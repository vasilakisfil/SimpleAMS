require "simple_ams"

module SimpleAMS
  class Options
    ELEMENTS = [:fields, :includes, :links, :metas, :type, :name].freeze

    attr_reader :resource, :allowed_options, :injected_options

    #injected_options is always a Hash object
    def initialize(resource, injected_options = {}, allowed_options = nil)
      @resource = resource
      @injected_options = injected_options
      if allowed_options
        @allowed_options = allowed_options
      else
        @allowed_options = injected_options.fetch(:serializer)
      end
    end

    def relation_options_for(relation_name)
      return _relation_options[relation_name] || {}
    end

    def primary_id
      return @primary_id if defined?(@primary_id)

      @primary_id = allowed_options.primary_id
      _primary_id = injected_options.fetch(:primary_id, nil)
      @primary_id = PrimaryId.new(*_primary_id) if _primary_id

      return @primary_id ||= PrimaryId.new(:id)
    end

    def type
      return @type if defined?(@type)

      @type = allowed_options.type
      _type = injected_options.fetch(:type, nil)
      @type = Type.new(*_type) if _type
      #TODO: add tests for that
      if @type.name.nil?
        if resource.is_a?(Array)
          @type = Type.new(resource.first.class.to_s.downcase)
        else
          @type = Type.new(resource.class.to_s.downcase)
        end
      end

      return @type
    end

    #that's handful
    def name
      @name ||= injected_options[:name] || type.name
    end

    #TODO: optimize for nested fields?
    def fields
      return @fields if defined?(@fields)

      injected = injected_options.fetch(:fields, nil)
      return @fields = allowed_options.attributes.uniq if injected.nil?

      return @fields = Fields.new(options_for(
        injected: Fields.new(injected_options.fetch(:fields, nil)),
        allowed: allowed_options.attributes
      ).uniq)
    end

    def includes
      return @includes if defined?(@includes)

      injected = injected_options.fetch(:includes, nil)
      return @includes = allowed_options.includes.uniq if injected.nil?

      return @includes = Includes.new(options_for(
        injected: Includes.new(injected_options.fetch(:includes, nil)),
        allowed: allowed_options.includes
      ).uniq)
    end

    #TODO: correctly loop over injected relations, although should be a rarely used feature
    def relations
      return @relations if defined?(@relations) #||= options_for(
        return @relations = allowed_options.relationships.select{
          |relation| includes.include?(relation.name)
        }
    end

    def links
      return @links if defined?(@links)

      injected = injected_options.fetch(:links, nil)
      injected = Links.new(injected.map{|l| Links::Link.new(*l.flatten)}) if injected

      return @links = Links.new(options_for(
        #TODO: correctly loop over injected properties
        injected: injected,
        allowed: allowed_options.links,
      ).uniq{|link| link.name})
    end

    def metas
      return @metas if defined?(@metas)

      injected = injected_options.fetch(:metas, nil)
      injected = Metas.new(injected.map{|l| Metas::Meta.new(*l.flatten)}) if injected

      return @metas = Metas.new(options_for(
        #TODO: correctly loop over injected properties
        injected: injected,
        allowed: allowed_options.metas,
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

      if injected_options.dig(:adapter)
        @adapter = Adapter.new(*injected_options.dig(:adapter))
      end
      @adapter = allowed_options.adapter if @adapter.nil?
      @adapter = Adapter.new(SimpleAMS::Adapters::AMS) if @adapter.nil?

      return @adapter
    end

    # the following should be the same for all (nested) serializers of the same document
    def exposed
      @exposed ||= injected_options.fetch(:expose, {})
    end

    private
      def options_for(allowed:, injected:)
        unless injected.nil?
          allowed = allowed & injected
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
  end
end
