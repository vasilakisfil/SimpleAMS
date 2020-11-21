class SimpleAMS::Document::PrimaryId
  attr_reader :name

  def initialize(options)
    @options = options
    @name = options.primary_id.name
  end

  def value
    if @options.serializer.respond_to?(name)
      @options.serializer.send(name)
    else
      @options.resource.send(name)
    end
  end

  def options
    @options.primary_id.options
  end
end
