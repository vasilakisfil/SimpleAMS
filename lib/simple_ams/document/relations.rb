require "simple_ams"

#TODO: Add memoization for the relations object (iteration + access)
module SimpleAMS
  class Document::Relations
    include Enumerable

    def initialize(options)
      @options = options
      @relations = options.relations
      @serializer = options.serializer
      @resource = options.resource
    end

    def [](key)
      found = relations.find{|relation| relation.name == key}
      return nil unless found

      return relation_for(found)
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
        SimpleAMS::Renderer.new(
          relation_value(relation.name),
          #TODO: this part here needs some work
          #4 options are merged:
          # *user injected when instantiating the SimpleAMS class
          # *relation options injected from parent serializer
          # *serializer class options
          SimpleAMS::Options.new(relation_value(relation.name), {
            injected_options: (relation.options || {}).merge(
              options.relation_options_for(
                relation.name
              ).merge(
                expose: options.expose
              )
            ).merge(
              name: relation.name,
              _internal: {
                module: serializer.class.to_s.rpartition('::').first
              }
            )
          }).as_hash
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

=begin TODO: Add that as public method, should help performance in edge cases
      def relationship_info_for(name)
        relations.find{|i| i.name == name}
      end
=end
  end
end
