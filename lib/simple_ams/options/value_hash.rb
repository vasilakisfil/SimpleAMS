require "simple_ams"

class SimpleAMS::Options
  class ValueHash
    attr_reader :value, :options

    def initialize(value, options = {})
      @value = value.to_sym if value
      @options = options[:options] || {}
    end

    alias_method :name, :value
  end

  class Adapter < ValueHash; end

  #it doesn't have any options, maybe move to a new class?
  class PrimaryId < ValueHash; end
end
