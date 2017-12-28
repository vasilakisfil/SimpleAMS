require "simple_ams"

module SimpleAMS
  class Serializer
    def initialize(resource, options = {})
      @resource, @options = resource, SimpleAMS::Options.new(resource, options)
    end

    #resource decorator ?
    def document
      @document ||= SimpleAMS::Document.new(options)
    end

    def as_json
      options.adapter.new(document).as_json
    end

    def to_json
      as_json.to_json
    end

    private
      attr_reader :resource, :options
  end

  class ArraySerializer
    def initialize(collection, options = {})
      @collection, @options = resource, SimpleAMS::Options.new(resource, options)
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
