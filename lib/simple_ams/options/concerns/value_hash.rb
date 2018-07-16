require "simple_ams"

class SimpleAMS::Options
  module Concerns
    module ValueHash
      attr_reader :value, :options

      def initialize(value, options = {})
        @value = value.is_a?(String) ? value.to_sym : value
        @options = options.kind_of?(Hash) ? options || {} : options
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
