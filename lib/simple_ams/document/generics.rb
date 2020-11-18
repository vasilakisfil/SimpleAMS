require 'simple_ams'

module SimpleAMS
  class Document::Generics
    include Enumerable

    Generic = Struct.new(:name, :value, :options)

    def initialize(options)
      @options = options
      @members = options.generics
    end

    def [](key)
      found = members.find { |generic| generic.name == key }
      return nil unless found

      with_decorator(found)
    end

    def each
      return enum_for(:each) unless block_given?

      members.each do |member|
        yield with_decorator(member)
      end

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

    def with_decorator(generic)
      Generic.new(
        generic.name,
        generic.respond_to?(:call) ? generic.value.call : generic.value,
        generic.options
      )
    end
  end
end
