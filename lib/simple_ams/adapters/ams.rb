require "simple_ams"

class SimpleAMS::Adapters::AMS
  attr_reader :document, :options

  def initialize(document, options = {})
    @document = document
    @options = options
  end

  def as_json
    return nil if document.resource.nil?

    hash = {}

    hash.merge!(fields)
    hash.merge!(relations) unless relations.empty?
    hash.merge!(links: links) unless links.empty?
    hash.merge!(metas: metas) unless metas.empty?
    hash.merge!(forms: forms) unless forms.empty?

    return {document.name => hash} if options[:root]
    return hash
  end

  def fields
    @fields ||= document.fields.inject({}){ |hash, field|
      hash[field.key] = field.value
      hash
    }
  end

  def links
    return @links ||= {} if document.links.empty?

    @links ||= document.links.inject({}){ |hash, link|
      hash[link.name] = link.value
      hash
    }
  end

  def metas
    @metas ||= document.metas.inject({}){ |hash, meta|
      hash[meta.name] = meta.value
      hash
    }
  end

  def forms
    @forms ||= document.forms.inject({}){ |hash, form|
      hash[form.name] = form.value
      hash
    }
  end

  def relations
    return @relations = {} if document.relations.available.empty?

    @relations ||= document.relations.available.inject({}){ |hash, relation|
      if relation.folder?
        value = relation.map{|doc| self.class.new(doc).as_json}
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
        {
          folder.name => documents,
          meta: metas,
          links: links
        }
      else
        documents
      end
    end

    def documents
      return folder.map{|document|
        adapter.new(document).as_json
      } || []
    end

    def metas
      @metas ||= folder.metas.inject({}){ |hash, meta|
        hash[meta.name] = meta.value
        hash
      }
    end

    def links
      @links ||= folder.links.inject({}){ |hash, link|
        hash[link.name] = link.value
        hash
      }
    end
  end
end
