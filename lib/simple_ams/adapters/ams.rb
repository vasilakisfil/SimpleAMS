require "simple_ams"

module SimpleAMS::Adapters
end

class SimpleAMS::Adapters::AMS
  attr_reader :decorator

  #add doclument (=model)
  #add something else other than decorator, maybe model/instance/record?
  #+links
  #+meta
  def initialize(decorator)
    @decorator = decorator
  end

  def as_json
    hash = {}

    decorator.model.fields.each{|field|
      value = decorator.value_for_field(field)
      if value.respond_to?(:as_json)
        hash[field] = value.as_json
      else
        hash[field] = value
      end
    }

    decorator.model.includes.each{|relation|
      value = decorator.value_for_relation(relation)

      if value.respond_to?(:as_json)
        hash[relation] = value.as_json
      else
        hash[relation] = value
      end
    }

    return hash
  end
end
