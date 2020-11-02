require 'simple_ams'

class SimpleAMS::Adapters::JSONAPI
  DEFAULT_OPTIONS = {
    skip_id_in_attributes: false,
    key_transform: nil
  }.freeze

  attr_reader :document, :options
  def initialize(document, options = {})
    @document = document
    @options = DEFAULT_OPTIONS.merge(options)
  end

  def as_json
    hash = {
      data: data
    }

    hash.merge!(links: links) unless links.empty?
    hash.merge!(metas: metas) unless metas.empty?
    hash.merge!(included: included) unless included.empty?

    hash
  end

  def data
    data = {
      transform_key(document.primary_id.name) => document.primary_id.value.to_s,
      type: document.type.value,
      attributes: fields
    }

    data.merge!(relationships: relationships) unless relationships.empty?

    data
  end

  def fields
    @fields ||= document.fields.each_with_object({}) do |field, hash|
      hash[transform_key(field.key)] = field.value unless options[:skip_id_in_attributes] && field_is_primary_id?(field)
    end
  end

  def transform_key(key)
    case options[:key_transform]
    when :camel
      key.to_s.split('_').map(&capitalize).join
    when :kebab
      key.to_s.gsub('_', '-')
    when :snake
      key
    else
      key
    end
  end

  def relationships
    return @relationships ||= {} if document.relations.empty?

    @relationships ||= document.relations.each_with_object({}) do |relation, hash|
      embedded_relation_data = embedded_relation_data_for(relation)
      hash.merge!(data: embedded_relation_data_for(relation)) unless embedded_relation_data.empty?

      embedded_relation_links = embedded_relation_links_for(relation)
      hash.merge!(links: embedded_relation_links_for(relation)) unless embedded_relation_links.empty?

      hash.merge!(relation.name => hash) unless hash.empty?
    end
  end

  def embedded_relation_data_for(relation)
    return {} if relation.embedded.generics[:skip_data]&.value

    if relation.folder?
      relation.each.map do |doc|
        {
          doc.primary_id.name => doc.primary_id.value.to_s,
          type: doc.type.name
        }
      end
    else
      {
        relation.primary_id.name => relation.primary_id.value.to_s,
        type: relation.type.name
      }
    end
  end

  def embedded_relation_links_for(relation)
    return {} if relation.embedded.links.empty?

    relation.embedded.links.each_with_object({}) do |link, hash|
      hash[link.name] = link.value
    end
  end

  def links
    return @links ||= {} if document.links.empty?

    @links ||= document.links.each_with_object({}) do |link, hash|
      hash[link.name] = link.value
    end
  end

  def metas
    @metas ||= document.metas.each_with_object({}) do |meta, hash|
      hash[meta.name] = meta.value
    end
  end

  def forms
    @forms ||= document.forms.each_with_object({}) do |form, hash|
      hash[form.name] = form.value
    end
  end

  def included
    return @included ||= [] if document.relations.available.empty?

    @included ||= document.relations.available.each_with_object([]) do |relation, array|
      next array if relation.embedded.generics[:skip_data]&.value

      array << if relation.folder?
                 relation.map { |doc| self.class.new(doc, options).as_json[:data] }
               else
                 self.class.new(relation, options).as_json[:data]
               end
    end.flatten
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

      hash
    end

    def documents
      @included = []
      folder.map  do |document|
        _doc = adapter.new(document, options).as_json
        @included << _doc[:included]
        _doc[:data]
      end || []
    end

    def included
      (@included || []).flatten
    end

    def metas
      @metas ||= folder.metas.each_with_object({}) do |meta, hash|
        hash[transform_key(meta.name)] = meta.value
      end
    end

    def links
      @links ||= folder.links.each_with_object({}) do |link, hash|
        hash[transform_key(link.name)] = link.value
      end
    end
  end

  private

  def field_is_primary_id?(field)
    field.key == document.primary_id.name
  end
end
