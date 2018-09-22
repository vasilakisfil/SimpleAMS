require "simple_ams"

class SimpleAMS::Adapters::JSONAPI
  DEFAULT_OPTIONS = {
    skip_id_in_attributes: true
  }

  attr_reader :document, :options
  def initialize(document, options = {})
    @document = document
    @options = DEFAULT_OPTIONS.merge(options)
  end

  def as_json
    hash = {
      data: data,
    }

    hash = hash.merge(links: links) unless links.empty?
    hash = hash.merge(metas: metas) unless metas.empty?
    hash = hash.merge(included: included) unless included.empty?

    return hash
  end

  def data
    data = {
      transform_key(document.primary_id.name) => document.primary_id.value.to_s,
      type: document.type.value,
      attributes: fields,
    }

    data = data.merge(relationships: relationships) unless relationships.empty?

    data
  end

  def fields
    @fields ||= document.fields.inject({}){ |hash, field|
      unless options[:skip_id_in_attributes] && field_is_primary_id?(field)
        hash[transform_key(field.key)] = field.value
      end
      hash
    }
  end

  def transform_key(key)
    key.to_s.gsub('_', '-')
  end

  def relationships
    return @relationships ||= {} if document.relations.empty?

    @relationships ||= document.relations.inject({}){ |hash, relation|
      _hash = {}
      embedded_relation_data = embedded_relation_data_for(relation)
      unless embedded_relation_data.empty?
        _hash = _hash.merge(data: embedded_relation_data_for(relation))
      end

      embedded_relation_links = embedded_relation_links_for(relation)
      unless embedded_relation_links.empty?
        _hash = _hash.merge(links: embedded_relation_links_for(relation))
      end

      hash = hash.merge(relation.name => _hash) unless _hash.empty?
      hash
    }
  end

  def embedded_relation_data_for(relation)
    return {} if relation.embedded.generics[:skip_data]&.value

    if relation.folder?
      value = relation.documents.map{|doc|
        {
          document.primary_id.name => document.primary_id.value.to_s,
          type: document.type.name
        }
      }
    else
      value = {
        relation.primary_id.name => document.primary_id.value.to_s,
        type: document.type.name
      }
    end
  end

  def embedded_relation_links_for(relation)
    return {} if relation.embedded.links.empty?

    relation.embedded.links.inject({}){ |hash, link|
      hash[link.name] = link.value
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

  def included
    return @included ||= [] if document.relations.available.empty?

    @included ||= document.relations.available.inject([]){ |array, relation|
      if relation.folder?
        array << relation.documents.map{|doc| self.class.new(doc).as_json[:data]}
      else
        array << self.class.new(relation).as_json[:data]
      end

      array
    }.flatten
  end

  class Collection < self
    attr_reader :folder, :adapter, :options

    def initialize(folder, options = {})
      @folder = folder
      @adapter = folder.adapter.value
      @options = options
    end

    def as_json
      hash = {
        data: documents
      }
      hash = hash.merge(meta: metas) unless metas.empty?
      hash = hash.merge(links: links) unless links.empty?

      return hash
    end

    def documents
      return folder.documents.map{|document|
        adapter.new(document).as_json[:data]
      } || []
    end

    def metas
      @metas ||= folder.metas.inject({}){ |hash, meta|
        hash[transform_key(meta.name)] = meta.value
        hash
      }
    end

    def links
      @links ||= folder.links.inject({}){ |hash, link|
        hash[transform_key(link.name)] = link.value
        hash
      }
    end

  end

  private
    def field_is_primary_id?(field)
      field.key == document.primary_id.name
    end

end

