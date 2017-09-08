require "simple_ams"

class SimpleAMS::Relationship
  def initialize(name, relation, options = {})
    @name = name
    @relation = relation
    @many = relation == :has_many ? true : false
  end

  def name
    @name
  end

  def array?
    @many
  end

  def single?
    !array
  end
end
