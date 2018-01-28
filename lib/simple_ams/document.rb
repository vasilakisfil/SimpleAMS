require "simple_ams"

#TODO: we also need the includes in here
class SimpleAMS::Document
  attr_reader :options, :serializer, :resource

  def initialize(options = SimpleAMS::Options.new)
    @options = options
    @serializer = options.serializer
    @resource = options.resource
  end

  def fields
    return @fields ||= self.class::Fields.new(options)
  end

  def relations
    return @relations ||= self.class::Relations.new(options)
  end

  def name
    options.name
  end

  def type
    options.type
  end

  def links
    return @links ||= self.class::Links.new(options)
  end

  def metas
    return @metas ||= self.class::Metas.new(options)
  end
end
