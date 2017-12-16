require "simple_ams"

module SimpleAMS
  class Options
    attr_reader :options, :resource

    def initialize(resource, options)
      @resource, @options = resource, options
    end

    def primary_id
      @primary_id = options.fetch(:primary_id) || :id
    end

    #TODO: optimize for nested fields?
    def fields
      return @fields ||= options_for(
        injected: self.class::Fields.new(options.fetch(:fields, [])),
        allowed: serializer.class.attributes
      )
    end

    def includes
      return @includes ||= options_for(
        injected: self.class::Includes.new(options.fetch(:includes, [])),
        allowed: serializer.class.includes
      )
    end

    def relations
      return @relations if defined?(@relations) #||= options_for(
        #TODO: correctly loop over injected properties
        #injected: self.class::Relation.new(options.fetch(:relations, {})),
        #allowed: serializer.class.relationships
        return @relations = serializer.class.relationships.select{
          |relation| includes.include?(relation.name)
        }
    end

    def links
      return @links ||= options_for(
        #TODO: correctly loop over injected properties
        injected: options.fetch(:links, {}),
        allowed: serializer.class.links,
      )
    end

    def meta
      return @meta ||= options_for(
        #TODO: correctly loop over injected properties
        injected: options.fetch(:meta, {}),
        allowed: serializer.class.meta
      )
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

    #TODO: use SimpelAMS.adapters.register to register internal adapters
    #expose it as a public API as well
    def adapter
      return @adapter if defined?(@adapter)

      #TODO: improve me
      name = options.dig(:adapter, :name)
      name = serializer.class.adapter.name if name.nil?

      if name.nil?
        return @adapter = SimpleAMS::Adapters::AMS
      else
        if name.is_a? Symbol
          return @adapter = Object.const_get("SimpleAMS::Adapters::#{name}")
        elsif name.is_a? Class
          @adapter = name
        else
          raise "Wrong adapter type: #{name}"
        end
      end
    end

    # the following should be the same for all (nested) serializers of the same document
    def exposed
      @exposed ||= options.fetch(:expose, {})
    end

    private
      def options_for(allowed:, injected:)
        unless injected.empty?
          allowed = allowed & injected
        end

        return allowed
      end
  end
end
