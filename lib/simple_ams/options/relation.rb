require "simple_ams"

class SimpleAMS::Options
  class Relation
    include SimpleAMS::Options::Concerns::NameValueHash

    def initialize(name, value, options = {})
      @name = name.is_a?(String) ? name.to_sym : name
      @value = value.to_sym
      @options = options

      @many = relation == :has_many ? true : false
    end

    alias_method :relation, :value

    def array?
      @many
    end

    def single?
      !array
    end
  end
end
