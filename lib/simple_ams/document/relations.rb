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
        Relationship.new(
          SimpleAMS::Serializer.new(
            relation_value(relation.name),
            #TODO: this part here needs some work
            #3 options are merged:
            # *user injected when instantiating the SimpleAMS class
            # *relation options injected from parent serializer
            # *serializer class options
            merged_options(
              relation.options, options.injected_options_for(relation.name)
            ).merge({
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
        relations.find{|i| i.name == name}
      end

      #merges the injected, along with the parent serializer injected options
      #probably needs better work, maybe exploit existing Options class?
      def merged_options(parent_options, injected_options)
        elements = [:fields, :includes, :links, :metas, :type]
        #does this really work for deep deep options?
        _options = parent_options.dup

        elements.each do |key|
          _options[key] = (parent_options[key] || []) & (injected_options[key] || [])
        end

        return _options
      end

      #we might need to move this somewhere else
      class Relationship
        include SimpleAMS::Options::Concerns::ValueHash

        alias_method :info, :options
      end
  end
end
