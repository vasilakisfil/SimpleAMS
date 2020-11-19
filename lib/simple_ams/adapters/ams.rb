require 'simple_ams'

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

    return { document.name => hash } if options[:root]

    hash
  end

  def fields
    @fields ||= document.fields.each_with_object({}) do |field, hash|
      hash[field.key] = field.value
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

  def relations
    return @relations = {} if document.relations.available.empty?

    @relations ||= document.relations.available.each_with_object({}) do |relation, hash|
      value = if relation.folder?
                relation.map { |doc| self.class.new(doc).as_json }
              else
                self.class.new(relation).as_json
              end
      hash[relation.name] = value
    end
  end

  class Collection < self
    attr_reader :folder, :adapter, :options

    def initialize(folder, options = {})
      super
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
      folder.map do |document|
        adapter.new(document).as_json
      end || []
    end

    def metas
      @metas ||= folder.metas.each_with_object({}) do |meta, hash|
        hash[meta.name] = meta.value
      end
    end

    def links
      @links ||= folder.links.each_with_object({}) do |link, hash|
        hash[link.name] = link.value
      end
    end
  end
end
