class SimpleAMS::Model
  def initialize(serializer, options = {})
    @serializer = serializer
    @options = options
  end

  def fields
    return @fields if defined?(@fields)

    @fields = @serializer.class.attributes #allowed fields
    @_fields = @options.fetch(:fields, {})

    unless @_fields.empty?
      @fields = @fields & @_fields
    end

    return @fields
  end

  def includes
    return @includes if defined?(@includes)

    @includes = serializer.class.includes
    unless includes.empty? || includes.nil?
      @includes = @includes & includes
    end

    return @includes
  end
end
