module Sequel

  extension :schema_dumper

  class Database

    def schema_to_hash(name)
      {
        :columns => schema(name).map do |name, info|
          _, name, db_type, options = column_schema_to_generator_opts(name, info, {})
          {
            :name => name,
            :db_type => if info[:type] == :enum
                          "enum"
                        else
                          COLUMN_TYPE_CLASS_TO_STRING[db_type]
                        end,
            :options => options,
            :raw_info => info
          }
        end,
        # this allows for multi-column primary keys to be migrated
        :primary_keys => schema(name).reject { |_, info| info[:primary_key] != true }.map do |name, info|
          name
        end,
        :datetime_default => schema(name).reject { |_, info| ( info[:type] != :datetime || info[:default] == "nil" ) }.map do |name, info|
          {
            :column_name => name,
            :default_value => info[:default]
          }
        end,
        :from_db => self.database_type
      }
    end

    def hash_to_schema(name, hash, &cb)
      db_conn = self.dup
      generator = Sequel::Schema::Generator.new(self) do
        hash[:columns].each do |column|
          if column[:db_type] != "enum"
            type = COLUMN_TYPE_STRING_TO_CLASS[column[:db_type]]
            raise "invalid type" unless type
          else
            db_conn["CREATE TYPE #{name}_#{column[:name]} AS #{column[:raw_info][:db_type]}"].all
            type = "#{name}_#{column[:name]}"
          end
          if(hash[:from_db] == :mysql && db_conn.database_type == :postgres && column[:raw_info][:auto_increment] == true)
            type = "Serial"
          end
          self.send(type.to_s, column[:name], column[:options])
        end
        self.send("primary_key", hash[:primary_keys]) if hash[:primary_keys].any?
      end
      self.create_table(name, :generator => generator)
      hash[:datetime_default].each do |row|
        if database_type == :postgres
          self["ALTER TABLE ? ALTER COLUMN ? SET DEFAULT CURRENT_TIMESTAMP", name, row[:column_name]].all
        end
      end
    end

    def not_transferred(name) 
      if self.database_type == :mysql
        self["SELECT column_name, extra FROM information_schema.columns WHERE table_schema = '#{self.opts[:database]}' AND table_name = '#{name}' AND length(extra) > 0"].all.map do |row|
          if row[:extra].downcase.include? 'on update'
            puts "\tNOT MIGRATED: #{row[:extra]} on COLUMN #{row[:column_name]}"
          end
        end
      end
    end

    COLUMN_TYPE_STRING_TO_CLASS = {
      "string" => String,
      "integer" => Integer,
      "fixnum" => Fixnum,
      "bignum" => Bignum,
      "float" => Float,
      "numeric" => Numeric,
      "bigdecimal" => BigDecimal,
      "date" => Date,
      "datetime" => DateTime,
      "time" => Time,
      "file" => File,
      "trueclass" => TrueClass,
      "falseclass" => FalseClass
    }

    COLUMN_TYPE_CLASS_TO_STRING = COLUMN_TYPE_STRING_TO_CLASS.dup.invert

    GET_MYSQL_FOREIGN_KEYS = (<<-end_sql
      select kcu.constraint_name, kcu.column_name, kcu.referenced_table_name, kcu.referenced_column_name, rc.update_rule, rc.delete_rule
        from information_schema.key_column_usage as kcu, information_schema.referential_constraints rc, information_schema.table_constraints tc
       where ( tc.constraint_schema = ? and tc.table_name = ? and tc.constraint_type = 'FOREIGN KEY' )
         and tc.constraint_name = rc.constraint_name
         and ( rc.constraint_schema = ? and rc.table_name = ? )
         and kcu.constraint_name = tc.constraint_name
         and ( kcu.constraint_schema = ? and kcu.table_name = ? )
    end_sql
    ).strip.gsub(/\s+/, ' ').freeze

   def read_extra_ddl(name)
      { 
        :serial_columns => schema(name).reject { |_, info| info[:auto_increment] != true }.map do |name, info|
          name
        end,
        :indexes => self.indexes(name),
        :foreign_keys => if self.database_type == :mysql
                           self[GET_MYSQL_FOREIGN_KEYS, self.opts[:database], name.to_s, self.opts[:database], name.to_s, self.opts[:database], name.to_s].all.map do |row|
                             { 
                               :constraint_name => row[:constraint_name].to_sym,
                               :column_name => row[:column_name].to_sym,
                               :referenced_table_name => row[:referenced_table_name].to_sym,
                               :referenced_column_name => row[:referenced_column_name].to_sym,
                               :update_rule => row[:update_rule].downcase.to_sym,
                               :delete_rule => row[:delete_rule].downcase.to_sym
                             }
                           end
                         end,
        :from_db_type => self.database_type
      }
    end

    def write_extra_ddl(name, hash)
      if hash[:indexes].count > 0
        print "\t       index:"
        hash[:indexes].each do |index_name, index|
          print " #{index_name}"

          # mysql index namespaces are per table, vs per database, so it is possible for
          # there to be, in a mysql->postgresql migration, index name conflicts.
  
          # this code checks to see if its coming *from* a mysql database to postgresql,
          # and, if so, makes sure that an attempt to create a second idx of the same name
          # doesn't results in a failed migration, but just renames the index to prepend
          # table name
          if hash[:from_db_type] == :mysql && self.database_type == :postgres
            if self[:pg_class].filter(:relname => index_name.to_s, :relkind => 'i').all.count > 0
              index_name = "#{name}_#{index_name}"
            end
          end
          self.add_index(name, index.delete(:columns), index.merge(:name => index_name))
        end
        puts ""
      end
      if hash[:foreign_keys].count > 0
        print "\tforeign keys:"
        hash[:foreign_keys].each do |row|
          print " #{row[:constraint_name]}"
          self.alter_table name do
            add_foreign_key( [ row[:column_name] ] , row[:referenced_table_name], { :key => row[:referenced_column_name], :on_delete => row[:delete_rule], :on_update => row[:update_rule] })
          end
        end
        puts ""
      end
      if self.database_type == :postgres && hash[:serial_columns].count > 0
        print "\t   sequences:"
        hash[:serial_columns].each do |column|
          print " #{column}"
          self["SELECT * FROM setval(?, ( SELECT max(?) FROM ? ), true)", "#{name}_#{column}_seq", column, name].all
        end
        puts ""
      end
    end
  end
end
