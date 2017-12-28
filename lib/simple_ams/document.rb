require "simple_ams"

#TODO: we also need the includes in here
class SimpleAMS::Document
  attr_reader :options, :serializer, :resource

  def initialize(options = {})
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

  def relation(name)
  end

  def links
    {}
  end

  def meta
    {}
  end
end
