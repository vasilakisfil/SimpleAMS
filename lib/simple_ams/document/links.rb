require "simple_ams"

module SimpleAMS
  class Document::Links
    include Enumerable

    Link = Struct.new(:name, :value, :options)

    def initialize(options)
      @options = options
      @members = options.links
    end

    def [](key)
      found = members.find{|link| link.name == key}
      return nil unless found

      return with_decorator(found)
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      members.each{ |member|
        yield with_decorator(member)
      }

      self
    end

    def any?
      members.any?
    end

    def empty?
      members.empty?
    end

    private
      attr_reader :members, :options

      def with_decorator(link)
        Link.new(
          link.name,
          link.respond_to?(:call) ? link.value.call : link.value,
          link.options
        )
      end
  end
end

