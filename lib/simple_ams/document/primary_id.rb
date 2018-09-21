module SimpleAMS
  class Document::PrimaryId
    attr_reader :name

    def initialize(options)
      @options = options
      @name = options.primary_id.name
    end

    def value
      if options.serializer.respond_to?(@key)
        Field.new(key, options.serializer.send(@name))
      else
        Field.new(key, options.resource.send(key))
      end
    end

    def options
      @options.primary_id.options
    end

    private
      attr_reader :options
  end
end

