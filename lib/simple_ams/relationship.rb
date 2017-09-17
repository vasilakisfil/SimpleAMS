require "simple_ams"

class SimpleAMS::Relationship
  attr_reader :value, :info
  def initialize(value, info)
    @value, @info = value, info
  end

  class Info
    attr_reader :options

    def initialize(name, relation, options = {})
      @name = name
      @relation = relation
      @options = options

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
end
