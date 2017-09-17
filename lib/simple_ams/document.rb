require "simple_ams"

class SimpleAMS::Document
  attr_reader :serializer, :options

  def initialize(options = {})
    @options = options
    @serializer = options.serializer
  end

  def fields
    return @fields if defined?(@fields)

    @fields = serializer.class.attributes #allowed fields
    instance_fields = options.fields

    unless instance_fields.empty?
      @fields = @fields & instance_fields
    end

    return @fields
  end

  def includes
    return @includes if defined?(@includes)

    @includes = serializer.class.relationships.map(&:name)

    instance_includes = options.includes
    unless instance_includes.empty? || instance_includes.nil?
      @includes = @includes & instance_includes
    end

    return @includes
  end

  def links
    {}
  end

  def meta
    {}
  end

  def relationships
    serializer.class.relationships
  end

  def relationship_for(name)
    relationships.find{|i| i.name == name}
  end
end
