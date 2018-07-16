require "simple_ams"

class SimpleAMS::Options
  module Concerns
    module NameValueHash
      attr_reader :name, :value, :options

      def initialize(name, value, options = {}, resource:)
        @name = name.is_a?(String) ? name.to_sym : name
        if value.is_a?(Proc)
          _value = value.call(resource)
          @value = _value.first
          @options = _value.last[:options] || {}
        else
          @value = value
          @options = options[:options] || {}
        end
      end

      def raw
        [name, value, {options: options}]
      end

      private
        attr_writer :name, :value, :options
    end
  end
end
