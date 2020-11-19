require 'simple_ams'

class SimpleAMS::Document::Fields
  include Enumerable

  Field = Struct.new(:key, :value)

  def initialize(options)
    @options = options
    @members = options.fields # [:field1, :field2]
  end

  def [](key)
    found = members.find { |field| field == key }
    return nil unless found

    value_of(found)
  end

  # TODO: Can we make this faster?
  def each
    return enum_for(:each) unless block_given?

    members.each do |key|
      yield value_of(key)
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

  def value_of(key)
    if options.serializer.respond_to?(key)
      Field.new(key, options.serializer.send(key))
    else
      Field.new(key, options.resource.send(key))
    end
  end
end
