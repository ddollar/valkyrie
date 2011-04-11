require "csv"
require "sequel"
require "valkyrie"
require "valkyrie/endpoint"

class Valkyrie::Database < Valkyrie::Endpoint

  Sequel.extension :schema_to_hash

  attr_reader :db

  def initialize(uri)
    @db = Sequel.connect(uri)
    Sequel::MySQL.convert_invalid_date_time = nil if @db.adapter_scheme == :mysql
  end

  def tables
    db.schema_to_hash
  end

  def create_table(name, schema)
    db.drop_table(name) if db.table_exists?(name)
    db.hash_to_schema(name, schema)
  end

  def dump_table(name, stream)
    columns = db.schema(name).map(&:first)
    dataset = db[name.to_sym]

    stream.puts CSV.generate_line(columns.map(&:to_s))
    dataset.each do |row|
      stream.puts CSV.generate_line(columns.map { |c| row[c] })
    end

    columns
  end

  def load_table(name, stream)
    csv = CSV.new(stream)

    columns = csv.gets
    csv.each do |row|
      db[name].insert columns, row
    end
  end

end

