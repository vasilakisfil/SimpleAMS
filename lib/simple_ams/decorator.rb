require "simple_ams"

class SimpleAMS::Decorator
  attr_reader :model, :resource

  def initialize(model, resource)
    @model, @resource = model, resource
  end

  #maybe merge those 2 ?
  def value_for_field(field)
    if model.serializer.respond_to?(field)
      serializer.send(field)
    else
      resource.send(field)
    end
  end

  def value_for_relation(relation)
    if model.serializer.respond_to?(relation)
      serializer.send(relation)
    else
      resource.send(relation)
    end
  end

end
