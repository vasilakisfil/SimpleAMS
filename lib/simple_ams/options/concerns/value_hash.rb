require "simple_ams"

class SimpleAMS::Options
  module Concerns
    module ValueHash
      attr_reader :value, :options

      def initialize(value, options = {}, resource:)
        if value.is_a?(Proc) #TODO: maybe we should do duck typing instead?
          _value = value.call(resource)
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

      alias_method :name, :value

      def raw
        [value, options]
      end

      private
        attr_writer :value, :options
    end
  end
end
