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

  def relation(name)
    SimpleAMS::Relationship.new(
      SimpleAMS::Serializer.new(
        _relation(name),
        document.relationship_for(name).options.merge({
          expose: document.options.exposed
        })
      ),
      document.relationship_for(name)
    )
  end

  def _relation(name)
    if document.serializer.respond_to?(name)
      serializer.send(name)
    else
      resource.send(name)
    end
  end
end
