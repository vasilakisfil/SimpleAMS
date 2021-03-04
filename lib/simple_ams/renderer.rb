require 'simple_ams'

class SimpleAMS::Renderer
  def initialize(resource, options = {})
    @resource = resource
    @options = SimpleAMS::Options.new(resource, injected_options: options)
  end

  # resource decorator ?
  def document
    @document ||= SimpleAMS::Document.new(options)
  end

  def name
    @options.name
  end

  def as_json
    options.adapter.klass.new(document, options.adapter.options).as_json
  end

  def to_json(*_args)
    as_json.to_json
  end

  class Collection
    def initialize(collection, options = {})
      @collection = collection
      @options = SimpleAMS::Options.new(
        collection,
        injected_options: options.merge(_internal: is_collection)
      )
    end

    def folder
      @folder ||= SimpleAMS::Document::Folder.new(options)
    end

    def as_json
      options.adapter.klass::Collection.new(folder, options.adapter.options).as_json
    end

    def to_json(*_args)
      as_json.to_json
    end

    private

    attr_reader :collection, :options

    # rubocop:disable Naming/PredicateName
    def is_collection
      { is_collection: true }
    end
    # rubocop:enable Naming/PredicateName
  end

  private

  attr_reader :resource, :options
end
