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
    def initialize(resource, options = {})
      @resource, @options = resource, SimpleAMS::Options.new(resource, options)
    end

    def document
      @document ||= SimpleAMS::Document.new(options)
    end

    def as_json
      options.adapter.new(SimpleAMS::Decorator.new(document, resource)).as_json
    end

    def to_json
      as_json.to_json
    end

    private
      attr_reader :resource, :options
  end
end
