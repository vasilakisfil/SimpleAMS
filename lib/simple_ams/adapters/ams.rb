require "simple_ams"

module SimpleAMS::Adapters
end

class SimpleAMS::Adapters::AMS
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def as_json
    hash = {}

    document.fields.each{ |field|
      hash[field.key] = field.value.as_json
    }

    document.relations.each{|relation|
      binding.pry
      hash[relation.info.name] = relation.value.as_json
    }

    return hash
  end
end
