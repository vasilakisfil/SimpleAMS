require "simple_ams"

module SimpleAMS
  class Document::Relations
    include Enumerable

    def initialize(options)
      @options = options
      @relations = options.relations
      @serializer = options.serializer
      @resource = options.resource
    end

    def [](name)
      return relation_for(name)
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      relations.each{ |relation|
        yield relation_for(relation)
      }

      self
    end

    private
      attr_reader :options, :relations, :serializer, :resource

      def relation_for(relation)
        binding.pry
        SimpleAMS::Relationship.new(
          SimpleAMS::Serializer.new(
            relation_value(relation.name),
            relation.options.merge({
              expose: options.exposed
            })
          ),
          relation
        )
      end

      #TODO: rename that to relation and existing relation to relationship
      def relation_value(name)
        if serializer.respond_to?(name)
          serializer.send(name)
        else
          resource.send(name)
        end
      end

      def relationship_info_for(name)
        binding.pry
        relations.find{|i| i.name == name}
      end
  end
end
