require 'simple_ams'

class SimpleAMS::Document
  attr_reader :options, :embedded_options, :serializer, :resource

  def initialize(options, embedded_options = nil)
    @options = options
    @embedded_options = embedded_options
    @serializer = options.serializer
    @resource = options.resource
  end

  def primary_id
    @primary_id ||= self.class::PrimaryId.new(options)
  end

  def fields
    return @fields if defined?(@fields)
    return @fields = [] if options.fields.empty?

    @fields ||= self.class::Fields.new(options)
  end

  def relations
    return @relations if defined?(@relations)

    @relations ||= self.class::Relations.new(
      options, options.relations
    )
  end

  def name
    @name ||= options.name
  end

  def type
    @type ||= options.type
  end

  def adapter
    @adapter ||= options.adapter
  end

  def links
    return @links if defined?(@links)
    return @links = {} if options.links.empty?

    @links ||= self.class::Links.new(options)
  end

  def metas
    return @metas if defined?(@metas)
    return @metas = {} if options.metas.empty?

    @metas ||= self.class::Metas.new(options)
  end

  def forms
    return @forms if defined?(@forms)
    return @forms = {} if options.forms.empty?

    @forms ||= self.class::Forms.new(options)
  end

  def generics
    return @generics if defined?(@generics)
    return @generics = {} if options.generics.empty?

    @generics ||= self.class::Generics.new(options)
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def folder?
    @is_folder ||= is_a?(self.class::Folder)
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def document?
    !folder?
  end

  def embedded
    return nil unless embedded_options

    @embedded ||= SimpleAMS::Document.new(embedded_options)
  end

  class Folder < self
    include Enumerable
    attr_reader :members
    alias collection resource

    def initialize(options, embedded_options = nil)
      @_options = options
      @embedded_options = embedded_options
      @options = @_options.collection_options

      @members = options.collection
      @resource = options.resource
    end

    def each
      return enum_for(:each) unless block_given?

      members.each do |resource|
        yield SimpleAMS::Document.new(options_for(resource))
      end

      self
    end

    # do we really need this method ?
    def documents
      each.map
    end

    def resource_options
      _options
    end

    private

    attr_reader :_options

    def options_for(resource)
      if resource_options.serializer_class.respond_to?(:call)
        SimpleAMS::Options.new(resource, {
          injected_options: resource_options.injected_options.merge({
            serializer: serializer_for(resource)
          }),
          allowed_options: serializer_for(resource).options
        })
      else
        resource_options.with_resource(resource)
      end
    end

    def serializer_for(resource)
      serializer = resource_options.serializer_class
      serializer = serializer.call(resource) if serializer.respond_to?(:call)

      serializer
    end
  end
end
