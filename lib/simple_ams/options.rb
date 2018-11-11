require "simple_ams"

module SimpleAMS
  class Options
    include Concerns::TrackedProperties

    class Collection < self; end

    attr_reader :resource, :allowed_options, :injected_options

    #injected_options is always a Hash object
    def initialize(resource = nil, injected_options: {}, allowed_options: nil)
      initialize_tracking!
      @resource = resource
      @injected_options = injected_options || {}
      @_internal = @injected_options[:_internal] || {}
      @allowed_options = allowed_options || fetch_allowed_options
    end
    alias collection resource

    #performance enchancement method for non-polymorphic collections
    def with_resource(resource)
      @resource = resource

      clean_volatile_properties!

      return self
    end

    def relation_options_for(relation_name)
      return _relation_options[relation_name] || {}
    end

    def primary_id
      return tracked(__method__).value if tracked(__method__).value

      return tracked(__method__).value = array_of_value_hash_for(PrimaryId, :primary_id)
    end

    def type
      return tracked(__method__).value if tracked(__method__).value

      return tracked(__method__).value = array_of_value_hash_for(Type, :type)
    end

    def name
      @name ||= injected_options[:name] || allowed_options[:name] || type.name
    end

    #TODO: optimize for nested fields?
    def fields
      return @fields if defined?(@fields)

      return @fields = array_of_items_for(Fields, :fields)
    end

    def includes
      return @includes if defined?(@includes)

      return @includes = array_of_items_for(Includes, :includes)
    end

    #TODO: correctly loop over injected relations, although should be a rarely used feature
    def relations
      return @relations if defined?(@relations)

      relations = injected_options.fetch(:relations, nil)
      relations = allowed_options.fetch(:relations, []) if relations.nil?

      return @relations = Relations.new(relations, includes)
    end

    def links
      return tracked(__method__).value if tracked(__method__).value

      return tracked(__method__).value = array_of_name_value_hash_for(Links, Links::Link, :links)
    end

    def metas
      return tracked(__method__).value if tracked(__method__).value

      return tracked(__method__).value = array_of_name_value_hash_for(Metas, Metas::Meta, :metas)
    end

    def forms
      return tracked(__method__).value if tracked(__method__).value

      return tracked(__method__).value = array_of_name_value_hash_for(Forms, Forms::Form, :forms)
    end

    def generics
      return tracked(__method__).value if tracked(__method__).value

      return tracked(__method__).value = array_of_name_value_hash_for(
        Generics, Generics::Option, :generics
      )
    end

    #TODO: handle case of proc
    def serializer
      return @serializer if defined?(@serializer)

      _serializer = injected_options.fetch(:serializer, serializer_class)

      return @serializer = instantiated_serializer_for(_serializer)
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
=begin
      if @adapter.value.nil?
        @adapter = Adapter.new(SimpleAMS::Adapters::AMS, {
          resource: resource, serializer: serializer
        })
      end
=end

      return @adapter
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
        #relations: relations.raw, #TODO: why have I commented that out ?
        includes: includes.raw,
        links: links.raw,
        metas: metas.raw,
        expose: expose,
        _internal: _internal
      }
    end

    def collection_options
      return @collection_options if defined?(@collection_options)

      #TODO: Do we need that merge ?
      _injected_options = @injected_options.fetch(:collection, {}).merge({
        serializer: collection_serializer_class,
        adapter: adapter(_serializer: collection_serializer_class).raw,
        expose: expose
      })
      _allowed_options = @allowed_options.fetch(:collection).options

      return @collection_options = self.class::Collection.new(
        resource,
        injected_options: _injected_options,
        allowed_options: _allowed_options
      )
    end

    def serializer_class
      return @serializer_class if defined?(@serializer_class)

      @serializer_class = injected_options.fetch(:serializer, nil)

      return @serializer_class if @serializer_class 

      return @serializer_class = infer_serializer
    end

    #TODO: maybe have that inside :collection? (isomorphism)
    def collection_serializer_class
      return @collection_serializer_class if defined?(@collection_serializer_class)

      if serializer_class.is_a?(Proc) #TODO: maybe we should do duck typing instead?
        @collection_serializer_class = injected_options[:collection_serializer]
        if @collection_serializer_class.nil?
          raise "In case of a proc serializer, you need to specify a collection_serializer"
        end
      else
        @collection_serializer_class = serializer_class
      end

      return @collection_serializer_class
    end

    private
      attr_reader :_internal

      #TODO: add method-based links, should boost performance
      def array_of_name_value_hash_for(collection_klass, item_klass, name)
        injected = injected_options.fetch(name, nil)
        if injected
          injected = collection_klass.new(
            injected.map{|l| item_klass.new(*l.flatten, {
              resource: resource, serializer: serializer
            })}
          )
        end

        allowed = collection_klass.new(
          allowed_options.fetch(name).map{|l| item_klass.new(*l, {
            resource: resource, serializer: serializer
          })}
        )

        return collection_klass.new(priority_options_for(
          #TODO: correctly loop over injected properties
          injected: injected,
          allowed: allowed,
        ).uniq{|item| item.name})
      end

      def array_of_value_hash_for(klass, name)
        _options = injected_options.fetch(name, nil)
        _options = allowed_options.fetch(name, nil) unless _options

        return klass.new(*_options, {
          resource: resource, serializer: serializer
        })
      end

      def array_of_items_for(klass, name)
        injected = injected_options.fetch(name, nil)

        if injected.nil?
          return klass.new(allowed_options.fetch(name).uniq)
        else
          return klass.new(priority_options_for(
            injected: klass.new(injected_options.fetch(name, nil)),
            allowed: klass.new(allowed_options.fetch(name).uniq)
          ).uniq)
        end
      end

      def priority_options_for(allowed:, injected:)
        if not injected.nil?
          allowed = injected.class.new(
            injected.map{|s| s.is_a?(Hash) ? (s.first && s.first[0]) : s}
          ) & allowed
        end

        return allowed
      end

=begin
      def options_for(allowed:, injected:)
        (allowed || []).concat(injected || [])
      end
=end

      def _relation_options
        return @_relation_options if defined?(@_relation_options)

        @_relation_options = relations.inject({}){|memo, relation|
          includes_value = (injected_options[:includes] || {}).find{|incl_hash|
            incl_hash.is_a?(Hash) &&
              (incl_hash.first && incl_hash.first[0]).to_s == relation.name.to_s
          }
          if includes_value
            includes_value = includes_value[relation.name]
          else
            #it's important here to return empty array if nothing is found..
            includes_value = []
          end

          fields_value = (injected_options[:fields] || {}).find{|field_hash|
            field_hash.is_a?(Hash) &&
              (field_hash.first && field_hash.first[0]).to_s == relation.name.to_s
          }

          #.. while here just nil will work (pick default fields from serializer)
          fields_value = fields_value[relation.name] if fields_value

          memo[relation.name] = {
            includes: includes_value,
            fields: fields_value
          }
          memo
        }
      end

      #TODO: raise exception if both are nil!
      def fetch_allowed_options
        _serializer_class = self.serializer_class
        if _serializer_class.is_a?(Proc) #TODO: maybe we should do duck typing instead?
          _serializer_class = self.collection_serializer_class
        end

        if _serializer_class.respond_to?(:simple_ams?)
          return _serializer_class&.options
        else
          raise "#{_serializer_class} does not respond to SimpleAMS methods, did you include the DSL module?"
        end
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
        namespace = _internal[:module] ? "#{_internal[:module]}::" : ""
        resource_klass = resource.kind_of?(Array) ? resource[0].class : resource.class
        if resource_klass == NilClass
          return EmptySerializer
        else
          return Object.const_get("#{namespace}#{resource_klass.to_s}Serializer")
        end
      rescue NameError => _
        raise "Could not infer serializer for #{resource.class}, maybe specify it? (tried #{namespace}#{resource_klass.to_s}Serializer)"
      end

      class EmptySerializer
        include SimpleAMS::DSL
      end
  end
end
