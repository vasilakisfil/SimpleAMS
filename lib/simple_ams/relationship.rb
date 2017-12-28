require "simple_ams"

class SimpleAMS::Relationship
  attr_reader :value, :info
  def initialize(value, info)
    @value, @info = value, info
  end
end
