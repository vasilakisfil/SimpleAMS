require "simple_ams"

class SimpleAMS::Document
  attr_reader :options, :serializer, :resource

  def initialize(options = SimpleAMS::Options.new)
    @options = options
    @serializer = options.serializer
    @resource = options.resource
  end

  def fields
    return @fields ||= self.class::Fields.new(options)
  end

  def relations
    return @relations ||= self.class::Relations.new(options)
  end

  def name
    options.name
  end

  def type
    options.type
  end

  def adapter
    options.adapter
  end

  def links
    return @links ||= self.class::Links.new(options)
  end

  def metas
    return @metas ||= self.class::Metas.new(options)
  end

  class Collection < self
    attr_reader :collection

    def initialize(options)
      @options = options
      @collection = options.resource
    end

    def documents
      @documents = collection.map do |resource|
        SimpleAMS::Document.new(options_for(resource))
      end
    end

    private
      def options_for(resource)
        SimpleAMS::Options.new(resource, {
          injected_options: options.injected_options,
          allowed_options: options.allowed_options
        })
      end
  end
end
