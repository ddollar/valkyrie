require "sequel"
require "valkyrie"
require "valkyrie/endpoint"

class Valkyrie::Database < Valkyrie::Endpoint

  Sequel.extension :schema_to_hash

  attr_reader :db

  def initialize(uri)
    @db = Sequel.connect(uri)
  end

  def tables
    db.schema_to_hash
  end

  def create_table(name, schema)
    db.drop_table(name) if db.table_exists?(name)
    db.hash_to_schema(name, schema)
  end

  def dump_table(name, stream)
    raise "must override"
  end

  def load_table(name, stream)
    raise "must override"
  end

end

