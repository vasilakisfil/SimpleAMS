require "simple_ams"

class SimpleAMS::Options
  class NameValueHash
    attr_reader :name, :value, :options

    def initialize(name, value, options = {})
      @name = name.to_sym
      @value = value.to_sym
      @options = options[:options] || {}
    end
  end

  class Link < NameValueHash; end
  class Meta < NameValueHash; end
  class Relation < NameValueHash
    def initialize(name, value, options = {})
      @name = name.to_sym
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
