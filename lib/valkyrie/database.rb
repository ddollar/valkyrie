require "sequel"
require "valkyrie"

class Valkyrie::Database

  Sequel.extension :schema_to_hash
  Sequel.extension :pagination

  attr_reader :connection

  def initialize(uri)
    @connection = Sequel.connect(uri)
    Sequel::MySQL.convert_invalid_date_time = nil if @connection.adapter_scheme == :mysql
  end

  def transfer_to(db)
    tables.each do |name|
      print "transferring: #{name}"
      transfer_table(name, db)
    end
  end

  def transfer_table(name, db)
    db.connection.drop_table(name) if db.connection.table_exists?(name)
    db.connection.hash_to_schema(name, connection.schema_to_hash(name))

    columns = connection.schema(name).map(&:first)
    dataset = connection[name.to_sym]

    buffer = []

    dataset.each do |row|
      buffer << row
      if buffer.length > 500
        send_rows(db, name, columns, buffer)
        buffer.clear
      end
    end
    send_rows(db, name, columns, buffer) if buffer.length > 0
    puts

    columns
  end

  def send_rows(db, name, columns, rows)
    print "."
    data = rows.map { |row| columns.map { |c| row[c] } }
    db.connection[name].insert_multiple data
  end

  def tables
    @tables ||= connection.tables
  end

end

