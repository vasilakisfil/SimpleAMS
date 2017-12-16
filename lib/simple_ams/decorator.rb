require "simple_ams"

class SimpleAMS::Decorator
  attr_reader :document, :resource

  def initialize(document, resource)
    @document, @resource = document, resource
  end

  #maybe merge those 2 ?
  def field_value(name)
    if document.serializer.respond_to?(name)
      document.serializer.send(name)
    else
      resource.send(name)
    end
  end

end
