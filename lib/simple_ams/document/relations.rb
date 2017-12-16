require "simple_ams"

module SimpleAMS
  class Document::Relations
    include Enumerable

    def initialize(options)
      @options = options
      @members = options.includes #[:field1, :field2]
      @serializer = options.serializer
      @resource = options.resource
    end

    def [](name)
      return relation_for(name)
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      members.each{ |name|
        yield relation_for(name)
      }

      self
    end

    private
      attr_reader :members, :options, :serializer, :resource

      def relation_for(name)
        return {} unless relationship_info_for(name)

        SimpleAMS::Relationship.new(
          SimpleAMS::Serializer.new(
            relation(name),
            relationship_info_for(name).options.merge({
              expose: options.exposed
            })
          ),
          relationship_info_for(name)
        )
      end

      def relation(name)
        if serializer.respond_to?(name)
          serializer.send(name)
        else
          resource.send(name)
        end
      end

      def relationships
        serializer.class.relationships
      end

      def relationship_info_for(name)
        relationships.find{|i| i.name == name}
      end
  end
end
