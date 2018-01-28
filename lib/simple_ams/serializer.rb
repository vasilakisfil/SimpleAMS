require "simple_ams"

module SimpleAMS
  class Serializer
    def initialize(resource, options = {})
      @resource = resource
      @options = SimpleAMS::Options.new(
        resource: resource, injected_options: options
      )
    end

    #resource decorator ?
    def document
      @document ||= SimpleAMS::Document.new(options)
    end

    def name
      @options.name
    end

    def as_json
      options.adapter.klass.new(document).as_json
    end

    def to_json
      as_json.to_json
    end

    private
      attr_reader :resource, :options
  end

  class ArraySerializer
    def initialize(collection, options = {})
      @collection, @options = resource, SimpleAMS::Options.new(
        resource: resource, injected_options: options
      )
    end

    def document
      @document ||= SimpleAMS::Document.new(options)
    end

    #TODO: is #each enough interface?
    #Add collection-related attributes
    def as_json
      return @as_json if defined?(@as_json)

      return @as_json = @collection.map do |resource|
        options.adapter.new(SimpleAMS::Decorator.new(document, resource)).as_json
      end
    end

    def to_json
      as_json.to_json
    end

    private
      attr_reader :collection, :options
  end
end
