require "simple_ams"

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
      hash[relation.name] = relation.as_json
    }

    return hash
  end

  class Collection
    attr_reader :folder, :adapter

    def initialize(folder)
      @folder = folder
      @adapter = folder.adapter.value
    end

    def as_json
      documents
    end

    def documents
      return folder.documents.map{|document|
        adapter.new(document).as_json
      } || []
    end

  end
end
