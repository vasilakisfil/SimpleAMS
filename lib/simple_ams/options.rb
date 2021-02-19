require 'simple_ams'

class SimpleAMS::Options
  include Concerns::TrackedProperties

  class Collection < self; end

  attr_reader :resource, :allowed_options, :injected_options

  # injected_options is always a Hash object
  def initialize(resource = nil, injected_options: {}, allowed_options: nil)
    initialize_tracking!
    @resource = resource
    @injected_options = injected_options || {}
    @_internal = @injected_options[:_internal] || {}
    @allowed_options = allowed_options || fetch_allowed_options
  end
  alias collection resource

  # performance enchancement method for non-polymorphic collections
  def with_resource(resource)
    @resource = resource
    remove_instance_variable(:@serializer) if defined?(@serializer)
    clean_volatile_properties!

    self
  end

  def relation_options_for(relation_name)
    _relation_options[relation_name] || {}
  end

  def primary_id
    return tracked(:primary_id).value if tracked(:primary_id).value

    tracked(:primary_id).value = array_of_value_hash_for(PrimaryId, :primary_id)
  end

  def type
    return tracked(:type).value if tracked(:type).value

    tracked(:type).value = array_of_value_hash_for(Type, :type)
  end

  def name
    @name ||= injected_options[:name] || allowed_options[:name] || type.name
  end

  # TODO: optimize for nested fields?
  def fields
    return @fields if defined?(@fields)

    @fields = array_of_items_for(Fields, :fields)
  end

  def includes
    return @includes if defined?(@includes)

    @includes = array_of_items_for(Includes, :includes)
  end

  # TODO: correctly loop over injected relations, although should be a rarely used feature
  def relations
    return @relations if defined?(@relations)

    relations = injected_options.fetch(:relations, nil)
    relations = allowed_options.fetch(:relations, []) if relations.nil?

    @relations = Relations.new(relations, includes)
  end

  def links
    return tracked(:links).value if tracked(:links).value

    tracked(:links).value = array_of_name_value_hash_for(Links, Links::Link, :links)
  end

  def metas
    return tracked(:metas).value if tracked(:metas).value

    tracked(:metas).value = array_of_name_value_hash_for(Metas, Metas::Meta, :metas)
  end

  def forms
    return tracked(:forms).value if tracked(:forms).value

    tracked(:forms).value = array_of_name_value_hash_for(Forms, Forms::Form, :forms)
  end

  def generics
    return tracked(:generics).value if tracked(:generics).value

    tracked(:generics).value = array_of_name_value_hash_for(
      Generics, Generics::Option, :generics
    )
  end

  # TODO: handle case of proc
  def serializer
    return @serializer if defined?(@serializer)

    _serializer = injected_options.fetch(:serializer, serializer_class)

    @serializer = instantiated_serializer_for(_serializer)
  end

  def adapter(_serializer: nil)
    return @adapter if defined?(@adapter) && _serializer.nil?

    serializer = _serializer || serializer

    @adapter = Adapter.new(*injected_options.fetch(:adapter, [nil]), {
      resource: resource, serializer: serializer
    })
    if @adapter.value.nil?
      @adapter = Adapter.new(*allowed_options.fetch(:adapter, [nil]), {
        resource: resource, serializer: serializer
      })
    end
    #       if @adapter.value.nil?
    #         @adapter = Adapter.new(SimpleAMS::Adapters::AMS, {
    #           resource: resource, serializer: serializer
    #         })
    #       end

    @adapter
  end

  # the following should be the same for all (nested) serializers of the same document
  def expose
    @expose ||= injected_options.fetch(:expose, {})
  end

  def as_hash
    {
      adapter: adapter.raw,
      primary_id: primary_id.raw,
      type: type.raw,
      name: name,
      fields: fields.raw,
      serializer: serializer_class,
      # relations: relations.raw, #TODO: why have I commented that out ?
      includes: includes.raw,
      links: links.raw,
      metas: metas.raw,
      expose: expose,
      _internal: _internal
    }
  end

  def collection_options
    return @collection_options if defined?(@collection_options)

    # TODO: Do we need that merge ?
    _injected_options = @injected_options.fetch(:collection, {}).merge({
      serializer: collection_serializer_class,
      adapter: adapter(_serializer: collection_serializer_class).raw,
      expose: expose
    })
    _allowed_options = @allowed_options.fetch(:collection).options

    @collection_options = self.class::Collection.new(
      resource,
      injected_options: _injected_options,
      allowed_options: _allowed_options
    )
  end

  def serializer_class
    return @serializer_class if defined?(@serializer_class)

    @serializer_class = injected_options.fetch(:serializer, nil)

    return @serializer_class if @serializer_class

    @serializer_class = infer_serializer
  end

  # TODO: maybe have that inside :collection? (isomorphism)
  def collection_serializer_class
    return @collection_serializer_class if defined?(@collection_serializer_class)

    if serializer_class.is_a?(Proc) # TODO: maybe we should do duck typing instead?
      @collection_serializer_class = injected_options[:collection_serializer]
      if @collection_serializer_class.nil?
        raise 'In case of a proc serializer, you need to specify a collection_serializer'
      end
    else
      @collection_serializer_class = serializer_class
    end

    @collection_serializer_class
  end

  private

  attr_reader :_internal

  # TODO: add method-based links, should boost performance
  def array_of_name_value_hash_for(collection_klass, item_klass, name)
    injected = injected_options.fetch(name, nil)
    if injected
      injected = collection_klass.new(
        injected.map do |l|
          item_klass.new(*l.flatten, {
            resource: resource, serializer: serializer
          })
        end
      )
    end

    allowed = collection_klass.new(
      allowed_options.fetch(name).map do |l|
        item_klass.new(*l, {
          resource: resource, serializer: serializer
        })
      end
    )

    collection_klass.new(priority_options_for(
      # TODO: correctly loop over injected properties
      injected: injected,
      allowed: allowed
    ).uniq(&:name))
  end

  def array_of_value_hash_for(klass, name)
    _options = injected_options.fetch(name, nil)
    _options ||= allowed_options.fetch(name, nil)

    klass.new(*_options, {
      resource: resource, serializer: serializer
    })
  end

  def array_of_items_for(klass, name)
    injected = injected_options.fetch(name, nil)

    if injected.nil?
      klass.new(allowed_options.fetch(name).uniq)
    else
      klass.new(priority_options_for(
        injected: klass.new(injected_options.fetch(name, nil)),
        allowed: klass.new(allowed_options.fetch(name).uniq)
      ).uniq)
    end
  end

  def priority_options_for(allowed:, injected:)
    unless injected.nil?
      allowed = injected.class.new(
        injected.map { |s| s.is_a?(Hash) ? s.keys : s }.flatten
      ) & allowed
    end

    allowed
  end

  def _relation_options
    return @_relation_options if defined?(@_relation_options)

    # TODO: should use 2.7 filter_map soon
    @_relation_options = relations.each_with_object({}) do |relation, memo|
      includes_value = (injected_options[:includes] || {}).find do |incl_hash|
        next unless incl_hash.is_a?(Hash)

        incl_hash.keys.include?(relation.name)
      end
      includes_value = if includes_value
                         includes_value[relation.name]
                       else
                         # it's important here to return empty array if nothing is found..
                         []
                       end

      fields_value = (injected_options[:fields] || {}).find do |field_hash|
        next unless field_hash.is_a?(Hash)

        field_hash.keys.include?(relation.name)
      end

      # .. while here just nil will work (pick default fields from serializer)
      fields_value = fields_value[relation.name] if fields_value

      memo[relation.name] = {
        includes: includes_value,
        fields: fields_value
      }
    end
  end

  # TODO: raise exception if both are nil!
  def fetch_allowed_options
    _serializer_class = serializer_class
    _serializer_class = collection_serializer_class if _serializer_class.is_a?(Proc)

    unless _serializer_class.respond_to?(:simple_ams?)
      raise "#{_serializer_class} does not respond to SimpleAMS methods, did you include the DSL module?"
    end

    _serializer_class&.options
  end

  def instantiated_serializer_for(serializer_klass)
    serializer_klass.new.extend(
      SimpleAMS::Methy.of(
        expose.merge({
          object: resource
        })
      )
    )
  end

  def infer_serializer
    namespace = _internal[:module] ? "#{_internal[:module]}::" : ''
    resource_klass = resource.respond_to?(:to_a) && resource.respond_to?(:last) ? resource[0].class : resource.class
    if resource_klass == NilClass
      EmptySerializer
    else
      Object.const_get("#{namespace}#{resource_klass}Serializer")
    end
  rescue NameError => _e
    tried = "#{namespace}#{resource_klass}Serializer"
    raise "Could not infer serializer for #{resource.class}, maybe specify it? (tried #{tried})"
  end

  class EmptySerializer
    include SimpleAMS::DSL
  end
end
