require "simple_ams"

class SimpleAMS::Serializer
  attr_reader :serializer, :options

  def initialize(serializer, options = {})
    @serializer, @options = serializer, options
  end

  def fields
    return @fields if defined?(@fields)

    @fields = serializer.class.attributes #allowed fields
    instance_fields = options.fetch(:fields, {})

    unless instance_fields.empty?
      @fields = @fields & instance_fields
    end

    return @fields
  end

  def includes
    return @includes if defined?(@includes)

    @includes = serializer.class.relationships.map(&:name)

    instance_includes = options.fetch(:includes, {})
    unless instance_includes.empty? || instance_includes.nil?
      @includes = @includes & instance_includes
    end

    return @includes
  end

  def adapter
    SimpleAMS::Adapters::AMS
  end
end

