require 'simple_ams'

class SimpleAMS::Options
  module Concerns::NameValueHash
    attr_reader :name, :value, :options

    def initialize(name, value, options = {}, resource:, serializer:)
      @name = name.is_a?(String) ? name.to_sym : name
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
        @value = value
        @options = options || {}
      end
    end

    def raw
      [name, value, options]
    end

    def volatile?
      @volatile || false
    end

    private

    attr_writer :name, :value, :options
  end
end
