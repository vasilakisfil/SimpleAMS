require "simple_ams"

class SimpleAMS::Serializer
  def initialize(resource, options = {})
    @resource, @options = resource, Options.new(resource, options)
  end

  def document
    @document ||= SimpleAMS::Document.new(options)
  end

  def as_json
    options.adapter.new(SimpleAMS::Decorator.new(document, resource)).as_json
  end

  def to_json
    as_json.to_json
  end

  private
    attr_reader :resource, :options

    class Options
      def initialize(resource, options)
        @resource, @options = resource, options
      end

      def fields
        @fields ||= options.fetch(:fields, {})
      end

      def includes
        @includes ||= options.fetch(:includes, {})
      end

      def links
        @links ||= options.fetch(:links, {})
      end

      def meta
        @meta ||= options.fetch(:meta, {})
      end

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
        @adapter ||= begin
          name = options.dig(:adapter, :name)
          if name.nil?
            SimpleAMS::Adapters::AMS
          else
            if name.is_a? Symbol
              const_get("SimapleAMS::Adapters::#{name}")
            elsif name.is_a? Class
            else
              raise 'Wrong adapter type ?'
            end
          end
        end
      end

      # the following should be the same for all (nested) serializers of the same document
      def exposed
        @exposed ||= options.fetch(:expose, {})
      end

      private
        attr_reader :options, :resource
    end
end
