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
        name: :fields,
        injected: options.fetch(:fields, {}),
        allowed: serializer.class.attributes
      )
    end

    def includes
      return @includes ||= options_for(
        name: :includes,
        injected: options.fetch(:includes, {}),
        allowed: serializer.class.relationships.map(&:name)
      )
    end

    def links
      return @links ||= options_for(:links)
    end

    def meta
      return @meta ||= options_for(:meta)
    end

    #TODO: handle case of proc
    def serializer
      _serializer = options.fetch(:serializer)

      @serializer ||= _serializer.new.extend(
        SimpleAMS::Methy.of(
          exposed.merge({
            object: resource
          })
        )
      )
    end

    def adapter
      return @adapter if defined?(@adapter)

      name = options.dig(:adapter, :name)
      name = serializer.class.adapter.dig(:name) if name.nil?

      if name.nil?
        return @adapter = SimpleAMS::Adapters::AMS
      else
        if name.is_a? Symbol
          return @adapter = const_get("SimapleAMS::Adapters::#{name}")
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
      def options_for(name:, allowed:, injected:)
        klass = Object.const_get("#{self.class}::#{name.to_s.capitalize}")
        allowed = klass.new(allowed)
        injected = klass.new(injected)

        unless injected.empty?
          allowed = allowed & injected
        end

        return allowed
      end
  end
end
