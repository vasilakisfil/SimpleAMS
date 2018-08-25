require "simple_ams"

class SimpleAMS::Adapters::AMS
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def as_json
    hash = {}

    #TODO: I think bang method for merging is way faster ?
    hash = hash.merge(fields)
    hash = hash.merge(relations)
    hash = hash.merge(links: links) unless links.empty?
    hash = hash.merge(metas: metas) unless metas.empty?

    return hash
  end

  def fields
    @fields ||= document.fields.inject({}){ |hash, field|
      hash[field.key] = field.value.as_json
      hash
    }
  end

  def relations
    @relations ||= document.relations.inject({}){ |hash, relation|
      hash[relation.name] = relation.as_json
      hash
    }
  end

  def links
    @links ||= document.links.inject({}){ |hash, link|
      hash[link.name] = link.value.as_json
      hash
    }
  end

  def metas
    @metas ||= document.metas.inject({}){ |hash, meta|
      hash[meta.name] = meta.value.as_json
      hash
    }
  end

  class Collection < self
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
