require "simple_ams"

class SimpleAMS::Options
  module Concerns
    module NameValueHash
      attr_reader :name, :value, :options

      def initialize(name, value, options = {}, resource:, serializer:)
        @name = name.is_a?(String) ? name.to_sym : name
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
          @value = value
          @options = options || {}
        end
      end

      def raw
        [name, value, options]
      end

      private
        attr_writer :name, :value, :options
    end
  end
end
