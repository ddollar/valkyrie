module Sequel

  extension :schema_dumper

  class Database

    def schema_to_hash(name)
      {
        :columns => schema(name).map do |name, info|
          _, name, db_type, options = column_schema_to_generator_opts(name, info, {})
          options[:primary_key] = true if info[:primary_key]
          {
            :name => name,
            :db_type => COLUMN_TYPE_CLASS_TO_STRING[db_type],
            :options => options
          }
        end,
        :indexes => self.indexes(name)
      }
    end

    def hash_to_schema(name, hash)
      generator = Sequel::Schema::Generator.new(self) do
        hash[:columns].each do |column|
          type = COLUMN_TYPE_STRING_TO_CLASS[column[:db_type]]
          raise "invalid type" unless type
          self.send(type.to_s, column[:name], column[:options])
        end
      end
      self.create_table(name, :generator => generator)
      hash[:indexes].values.each do |index|
        self.add_index(name, index.delete(:columns), index)
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
  end
end
