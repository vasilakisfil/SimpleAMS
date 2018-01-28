require "simple_ams"

class SimpleAMS::Options
  module Concerns
    module NameValueHash
      attr_reader :name, :value, :options

      def initialize(name, value, options = {})
        @name = name.is_a?(String) ? name.to_sym : name
        @value = value
        @options = options[:options] || {}
      end

      def raw
        [name, value, {options: options}]
      end

      private
        attr_writer :name, :value, :options
    end
  end
end
