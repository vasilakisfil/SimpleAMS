require "simple_ams"

class SimpleAMS::Serializer::AMS
  def initialize(resource, model)
    @model = model
  end

  def as_json
    fields.each{|field|
      hash[field] = @resource.send(field).as_json
    }

    #includes.each{|relation|
    #  hash[relation] = resource.send(relation)
    #}

    return hash
  end
end
