require "simple_ams"

module SimpleAMS
  class Options
    class Collection < self; end

    attr_reader :resource, :allowed_options, :injected_options

    #injected_options is always a Hash object
    def initialize(resource, injected_options: {}, allowed_options: nil)
      @resource = resource
      @injected_options = injected_options || {}
      @_internal = @injected_options[:_internal] || {}
      @allowed_options = allowed_options || fetch_allowed_options
    end
    alias collection resource

    def relation_options_for(relation_name)
      return _relation_options[relation_name] || {}
    end

    def primary_id
      return @primary_id if defined?(@primary_id)

      _options = injected_options.fetch(:primary_id, nil)
      _options = allowed_options.fetch(:primary_id, nil) unless _options

      return @primary_id ||= PrimaryId.new(*_options)
    end

    def type
      return @type if defined?(@type)

      _options = injected_options.fetch(:type, nil)
      _options = allowed_options.fetch(:type, nil) unless _options

      return @type ||= Type.new(*_options)
    end

    #that's handful
    def name
      @name ||= injected_options[:name] || allowed_options[:name] || type.name
    end

    #TODO: optimize for nested fields?
    def fields
      return @fields if defined?(@fields)

      injected = injected_options.fetch(:fields, nil)

      if injected.nil?
        return @fields = Fields.new(allowed_options.fetch(:fields).uniq)
      else
        return @fields = Fields.new(options_for(
          injected: Fields.new(injected_options.fetch(:fields, nil)),
          allowed: Fields.new(allowed_options.fetch(:fields).uniq)
        ).uniq)
      end
    end

    def includes
      return @includes if defined?(@includes)

      injected = injected_options.fetch(:includes, nil)

      if injected.nil?
        return @includes = Includes.new(allowed_options.fetch(:includes).uniq)
      else
        return @includes = Includes.new(options_for(
          injected: Includes.new(injected_options.fetch(:includes, nil)),
          allowed: Includes.new(allowed_options.fetch(:includes).uniq)
        ).uniq)
      end
    end

    #TODO: correctly loop over injected relations, although should be a rarely used feature
    def relations
      return @relations if defined?(@relations) #||= options_for(

      relations = injected_options.fetch(:relations, nil)
      relations = allowed_options.fetch(:relations, []) if relations.nil?

      return @relations = relations.map{|rel| Relation.new(*rel)}.select{
          |relation| includes.include?(relation.name)
        }
    end

    #TODO: add method-based links, should boost performance
    def links
      return @links if defined?(@links)

      injected = injected_options.fetch(:links, nil)
      if injected
        injected = Links.new(
          injected.map{|l| Links::Link.new(*l.flatten, resource: resource)}
        )
      end

      allowed = Links.new(
        allowed_options.fetch(:links).map{|l| Links::Link.new(*l, resource: resource)}
      )

      return @links = Links.new(options_for(
        #TODO: correctly loop over injected properties
        injected: injected,
        allowed: allowed,
      ).uniq{|link| link.name})
    end

    #TODO: add method-based metas, should boost performance
    def metas
      return @metas if defined?(@metas)

      injected = injected_options.fetch(:metas, nil)
      if injected
        injected = Metas.new(
          injected.map{|l| Metas::Meta.new(*l.flatten, resource: resource)}
        )
      end
      allowed = Metas.new(
        allowed_options.fetch(:metas).map{|l| Metas::Meta.new(*l, resource: resource)}
      )

      return @metas = Metas.new(options_for(
        #TODO: correctly loop over injected properties
        injected: injected,
        allowed: allowed,
      ).uniq{|meta| meta.name})
    end

    #TODO: handle case of proc
    def serializer
      return @serializer if defined?(@serializer)

      _serializer = injected_options.fetch(:serializer, serializer_class)

      return @serializer = _serializer.new.extend(
        SimpleAMS::Methy.of(
          expose.merge({
            object: resource
          })
        )
      )
    end

    def adapter
      return @adapter if defined?(@adapter)

      @adapter = Adapter.new(*injected_options.fetch(:adapter, [nil]))
      @adapter = Adapter.new(*allowed_options.fetch(:adapter, [nil])) if @adapter.value.nil?
      @adapter = Adapter.new(SimpleAMS::Adapters::AMS) if @adapter.value.nil?

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
        serializer: collection_serializer_class
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

      if serializer_class.is_a?(Proc)
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
=begin
      def is_collection?
        _internal[:is_collection] == true
      end
=end

      def options_for(allowed:, injected:)
        if not injected.nil?
          allowed = injected & allowed
        end

        return allowed
      end

      def _relation_options
        return @_relation_options if defined?(@_relation_options)
        #maybe save those in a constant?
        elements = [:fields, :includes, :links, :metas]

        return @_relation_options = elements.inject({}){|memo, element|
          injected_options.fetch(element, {}).select{|relation_options|
            relation_options.is_a?(Hash)
          }.reduce({}, :update).each { |key, value| #WTF is that ?
            memo[key] = {} if memo[key].nil?
            memo[key][element] = value
          }

          memo
        }
      end

      #TODO: raise exception if both are nil!
      def fetch_allowed_options
        _serializer_class = self.serializer_class
        if _serializer_class.is_a?(Proc)
          _serializer_class = self.collection_serializer_class
        end

        _allowed_options = _serializer_class&.options

        return _allowed_options
      end

      def infer_serializer
        namespace = _internal[:module] ? "#{_internal[:module]}::" : ""
        resource_klass = resource.kind_of?(Array) ? resource.first.class : resource.class
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
