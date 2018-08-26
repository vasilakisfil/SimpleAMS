require "simple_ams"

class SimpleAMS::Adapters::AMS
  attr_reader :document, :options

  def initialize(document, options = {})
    @document = document
    @options = options
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
      _value = field.value
      hash[field.key] = _value.respond_to?(:as_json) ? _value.as_json : _value
      hash
    }
  end

  def links
    @links ||= document.links.inject({}){ |hash, link|
      _value = link.value
      hash[link.name] = _value.respond_to?(:as_json) ? _value.as_json : _value
      hash
    }
  end

  def metas
    @metas ||= document.metas.inject({}){ |hash, meta|
      _value = meta.value
      hash[meta.name] = _value.respond_to?(:as_json) ? _value.as_json : _value
      hash
    }
  end

  def relations
    return {} if document.relations.empty?

    @relations ||= document.relations.inject({}){ |hash, relation|
      if relation.folder?
        value = relation.documents.map{|doc| self.class.new(doc).as_json}
      else
        value = self.class.new(relation).as_json
      end
      hash[relation.name] = value

      hash
    }
  end

  class Collection < self
    attr_reader :folder, :adapter, :options

    def initialize(folder, options = {})
      @folder = folder
      @adapter = folder.adapter.value
      @options = options
    end

    def as_json
      if options[:root]
        {folder.name => documents}
      else
        documents
      end
    end

    def documents
      return folder.documents.map{|document|
        adapter.new(document).as_json
      } || []
    end
  end
end
