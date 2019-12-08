require "simple_ams"

class SimpleAMS::Adapters::JSONAPI
  DEFAULT_OPTIONS = {
    skip_id_in_attributes: false,
    key_transform: nil
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

    hash.merge!(links: links) unless links.empty?
    hash.merge!(metas: metas) unless metas.empty?
    hash.merge!(included: included) unless included.empty?

    return hash
  end

  def data
    data = {
      transform_key(document.primary_id.name) => document.primary_id.value.to_s,
      type: document.type.value,
      attributes: fields,
    }

    data.merge!(relationships: relationships) unless relationships.empty?

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
    case options[:key_transform]
    when :camel
      key.to_s.split('_').map(&capitalize).join
    when :kebab
      key.to_s.gsub('_','-')
    when :snake
      key
    else
      key
    end
  end

  def relationships
    return @relationships ||= {} if document.relations.empty?

    @relationships ||= document.relations.inject({}){ |hash, relation|
      _hash = {}

      embedded_relation_data = embedded_relation_data_for(relation)
      unless embedded_relation_data.empty?
        _hash.merge!(data: embedded_relation_data_for(relation))
      end

      embedded_relation_links = embedded_relation_links_for(relation)
      unless embedded_relation_links.empty?
        _hash.merge!(links: embedded_relation_links_for(relation))
      end

      hash.merge!(relation.name => _hash) unless _hash.empty?
      hash
    }
  end

  def embedded_relation_data_for(relation)
    return {} if relation.embedded.generics[:skip_data]&.value

    if relation.folder?
      value = relation.each.map{|doc|
        {
          doc.primary_id.name => doc.primary_id.value.to_s,
          type: doc.type.name
        }
      }
    else
      value = {
        relation.primary_id.name => relation.primary_id.value.to_s,
        type: relation.type.name
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
      next array if relation.embedded.generics[:skip_data]&.value

      if relation.folder?
        array << relation.map{|doc| self.class.new(doc, options).as_json[:data]}
      else
        array << self.class.new(relation, options).as_json[:data]
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
      hash.merge!(meta: metas) unless metas.empty?
      hash.merge!(links: links) unless links.empty?
      hash.merge!(included: included) unless included.empty?

      return hash
    end

    def documents
      @included = []
      return folder.map{|document|
        _doc = adapter.new(document, options).as_json
        @included << _doc[:included]
        _doc[:data]
      } || []
    end

    def included
      (@included || []).flatten
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

