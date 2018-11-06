require "simple_ams"

class SimpleAMS::Options
  module Concerns
    module ValueHash
      attr_reader :value, :options
      alias :name :value

      def initialize(value, options = {}, resource:, serializer:)
        if value.is_a?(Proc) #TODO: maybe we should do duck typing instead?
          _value = value.call(resource, serializer)
          if _value.is_a?(Array) && _value.length > 1
            @value = _value.first
            @options = (_value.last || {}).merge(options || {})
          else
            @value = _value
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

      private
        attr_writer :value, :options
    end
  end
end
