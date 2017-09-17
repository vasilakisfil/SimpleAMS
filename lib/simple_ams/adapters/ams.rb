require "simple_ams"

module SimpleAMS::Adapters
end

class SimpleAMS::Adapters::AMS
  attr_reader :decorator

  def initialize(decorator)
    @decorator = decorator
  end

  def as_json
    hash = {}

    decorator.document.fields.each{ |field|
      value = decorator.field_value(field)
      if value.respond_to?(:as_json)
        hash[field] = value.as_json
      else
        hash[field] = value
      end
    }

    decorator.document.includes.each{|relation|
      value = decorator.relation(relation).value

      if value.respond_to?(:as_json)
        hash[relation] = value.as_json
      else
        hash[relation] = value
      end
    }

    return hash
  end
end
