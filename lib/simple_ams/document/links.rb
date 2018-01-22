require "simple_ams"

module SimpleAMS
  class Document::Links
    include Enumerable

    attr_reader :members

    def initialize(options)
      @options = options
      @members = options.links
    end

    def [](key)
      return with_decorator(options.links[key])
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      members.each{ |member|
        yield with_decorator(member)
      }

      self
    end

    private
      attr_reader :options

      def with_decorator(link)
        Link.new(link)
      end

      #memoization maybe ?
      class Link
        def initialize(link)
          @link = link
        end

        def name
          link.name
        end

        def value
          link.respond_to?(:call) ? link.value.call : link.value
        end

        def options
          link.options
        end

        private
          attr_reader :link
      end
  end
end

