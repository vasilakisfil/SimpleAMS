require 'simple_ams'

class SimpleAMS::Options
  module Concerns::ValueHash
    attr_reader :value, :options
    alias name value

    def initialize(value, options = {}, resource:, serializer:)
      if value.respond_to?(:call)
        @volatile = true
        computed_value = value.call(resource, serializer)
        if computed_value.is_a?(Array) && computed_value.length > 1
          @value = computed_value[0]
          @options = (computed_value[-1] || {}).merge(options || {})
        else
          @value = computed_value
          @options = options || {}
        end
      else
        @value = value.is_a?(String) ? value.to_sym : value
        @options = options || {}
      end
    end

    def raw
      [value, options]
    end

    def volatile?
      @volatile || false
    end

    private

    attr_writer :value, :options
  end
end
