require "simple_ams"

module SimpleAMS
  class Options
    ELEMENTS = [:fields, :includes, :links, :metas, :type, :name].freeze

    attr_reader :resource, :allowed_options, :injected_options

    #injected_options is always a Hash object
    def initialize(resource:, injected_options: {}, allowed_options: nil)
      @resource = resource
      @injected_options = injected_options
      @_internal = injected_options[:_internal] || {}
      @allowed_options = allowed_options || injected_options.fetch(:serializer, nil)&.options
      @allowed_options = infer_serializer_for(resource).options if @allowed_options.nil?
    end

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
      @name ||= injected_options[:name] || type.name
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
      return @relations = allowed_options.fetch(:relationships).map{|rel| Relation.new(*rel)}.select{
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

      _serializer = injected_options.fetch(:serializer)

      return @serializer = _serializer.new.extend(
        SimpleAMS::Methy.of(
          exposed.merge({
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
    def exposed
      @exposed ||= injected_options.fetch(:expose, {})
    end

    def as_hash
      {
        adapter: adapter.raw,
        primary_id: primary_id.raw,
        type: type.raw,
        fields: fields.raw,
        #relationships: relations.raw,
        includes: includes.raw,
        links: links.raw,
        metas: metas.raw,
        _internal: _internal
      }
    end

    private
      attr_reader :_internal

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
          }.reduce({}, :update).each { |key, value|
            memo[key] = {} if memo[key].nil?
            memo[key][element] = value
          }

          memo
        }
      end

      def infer_serializer_for(resource)
        namespace = _internal[:module] ? "#{_internal[:module]}::" : ""
        @serializer ||= Object.const_get("#{namespace}#{resource.class.to_s}Serializer")
      rescue NameError => _
        raise "Could not infer serializer for #{resource.class}, maybe specify it? (tried #{namespace}#{resource.class.to_s}Serializer)"
      end
  end
end
