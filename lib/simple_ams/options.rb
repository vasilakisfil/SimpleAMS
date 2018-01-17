require "simple_ams"

module SimpleAMS
  class Options
    attr_reader :options, :resource

    def initialize(resource, options)
      @resource, @options = resource, options
    end

    def injected_options_for(relation_name)
      return _injected_options[relation_name]
    end

    def primary_id
      return @primary_id if defined?(@primary_id)

      @primary_id = serializer.class.primary_id
      _primary_id = options.fetch(:primary_id, nil)
      @primary_id = PrimaryId.new(*_primary_id) if _primary_id

      return @primary_id ||= PrimaryId.new(:id)
    end

    def type
      return @type if defined?(@type)

      @type = serializer.class.type
      _type = options.fetch(:type, nil)
      @type = Type.new(*_type) if _type

      return @type ||= Type.new
    end

    #TODO: optimize for nested fields?
    def fields
      return @fields if defined?(@fields)

      injected = options.fetch(:fields, nil)
      return @fields = serializer.class.attributes.uniq if injected.nil?

      return @fields = Fields.new(options_for(
        injected: Fields.new(options.fetch(:fields, nil)),
        allowed: serializer.class.attributes
      ).uniq)
    end

    def includes
      return @includes if defined?(@includes)

      injected = options.fetch(:includes, nil)
      return @includes = serializer.class.includes.uniq if injected.nil?

      return @includes = Includes.new(options_for(
        injected: Includes.new(options.fetch(:includes, nil)),
        allowed: serializer.class.includes
      ).uniq)
    end

    #TODO: correctly loop over injected relations, although should be a rarely used feature
    def relations
      return @relations if defined?(@relations) #||= options_for(
        return @relations = serializer.class.relationships.select{
          |relation| includes.include?(relation.name)
        }
    end

    def links
      return @links if defined?(@links)

      injected = options.fetch(:links, nil)
      injected = Links.new(injected.map{|l| Links::Link.new(*l.flatten)}) if injected

      return @links = Links.new(options_for(
        #TODO: correctly loop over injected properties
        injected: injected,
        allowed: serializer.class.links,
      ).uniq{|link| link.name})
    end

    def metas
      return @metas if defined?(@metas)

      injected = options.fetch(:metas, nil)
      injected = Metas.new(injected.map{|l| Metas::Meta.new(*l.flatten)}) if injected

      return @metas = Metas.new(options_for(
        #TODO: correctly loop over injected properties
        injected: injected,
        allowed: serializer.class.metas,
      ).uniq{|meta| meta.name})
    end

    #TODO: handle case of proc
    def serializer
      return @serializer if defined?(@serializer)

      _serializer = options.fetch(:serializer)

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

      if options.dig(:adapter)
        @adapter = Adapter.new(*options.dig(:adapter))
      end
      @adapter = serializer.class.adapter if @adapter.nil?
      @adapter = Adapter.new(SimpleAMS::Adapters::AMS) if @adapter.nil?

      return @adapter
    end

    # the following should be the same for all (nested) serializers of the same document
    def exposed
      @exposed ||= options.fetch(:expose, {})
    end

    private
      def options_for(allowed:, injected:)
        unless injected.nil?
          allowed = allowed & injected
        end

        return allowed
      end

      def _injected_options
        return @_injected_options if defined?(@injected_options)
        #maybe save those in a constant?
        elements = [:fields, :includes, :links, :metas]

        return @_injected_options = elements.inject({}){|memo, element|
          options.fetch(element, {}).select{|relation_options|
            relation_options.is_a?(Hash)
          }.reduce({}, :update).each { |key, value|
            memo[key] = {} if memo[key].nil?
            memo[key][element] = value
          }

          memo
        }
      end
  end
end
