require "simple_ams"

module SimpleAMS
  class Document::Fields
    include Enumerable

    attr_reader :members

    def initialize(options)
      @options = options
      @members = options.fields #[:field1, :field2]
    end

    def [](key)
      found = members.find{|field| field == key}
      return nil unless found

      return with_decorator(found)
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      members.each{ |key|
        yield with_decorator(key)
      }

      self
    end

    private
      attr_reader :options

      def with_decorator(key)
        Field.new(
          options.resource,
          options.serializer,
          key,
          options
        )
      end

      class Field
        attr_reader :key

        #do we need to inject the whole options object?
        def initialize(resource, serializer, key, options)
          @resource = resource
          @serializer = serializer
          @key = key
          @options = options
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
