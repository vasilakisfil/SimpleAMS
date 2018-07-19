require "simple_ams"

class SimpleAMS::Options
  class Relation
    attr_reader :type, :name, :options
    def initialize(type, name, options = {})
      @type = type.to_sym
      @name = name.is_a?(String) ? name.to_sym : name
      @options = options

      @many = relation == :has_many ? true : false
    end

    alias relation name

    def raw
      [type, name, options]
    end

    def array?
      @many
    end

    def single?
      !array
    end

    private
      attr_writer :type, :name, :options
  end
end
