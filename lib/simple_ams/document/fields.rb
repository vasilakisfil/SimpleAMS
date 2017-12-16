require "simple_ams"

module SimpleAMS
  class Document::Fields
    include Enumerable

    def initialize(options)
      @options = options
      @members = options.fields #[:field1, :field2]
    end

    def [](key)
      return with_decorator(key)
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      members.each{ |key|
        yield with_decorator(key)
      }

      self
    end

    private
      attr_reader :members, :options

      def with_decorator(key)
        Decorator.new(
          options.resource,
          options.serializer,
          key
        )
      end

      class Decorator
        attr_reader :key

        #do we need to inject the whole options object?
        def initialize(resource, serializer, key)
          @resource = resource
          @serializer = serializer
          @key = key
        end

        def value
          return @value if defined?(@value)

          return @value = serializer.send(key) if serializer.respond_to? key
          return resource.send(key)
        end

        private
          attr_reader :resource, :serializer
      end
  end
end
