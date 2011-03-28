require "valkyrie"

class Valkyrie::Endpoint

  def tables
    raise "must override"
  end

  def drop_table(name)
    raise "must override"
  end

  def create_table(name, schema)
    raise "must override"
  end

  def dump_table(name, stream)
    raise "must override"
  end

  def load_table(name, stream)
    raise "must override"
  end

  def indexes
    raise "must override"
  end

  def drop_index(name)
    raise "must override"
  end

  def create_index(name, index)
    raise "must override"
  end

end

