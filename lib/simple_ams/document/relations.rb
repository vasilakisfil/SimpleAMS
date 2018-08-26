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

    def empty?
      count == 0
    end

    private
      attr_reader :options, :relations, :serializer, :resource

      def relation_for(relation)
        renderer_klass_for(relation).new(
          SimpleAMS::Options.new(
            relation_value_for(relation.name), relation_options_for(relation)
          )
        )
      end

      #TODO: rename that to relation and existing relation to relationship
      def relation_value_for(name)
        if serializer.respond_to?(name)
          serializer.send(name)
        else
          resource.send(name)
        end
      end

      #4 options are merged:
      # *user injected when instantiating the SimpleAMS class
      # *relation options injected from parent serializer
      # *serializer class options
      def relation_options_for(relation)
        _relation_options = {
          injected_options: (relation.options || {}).merge(
            options.relation_options_for(
              relation.name
            ).merge(
              expose: options.expose
            )
          ).merge(
            _internal: {
              module: serializer.class.to_s.rpartition('::').first
            }
          )
        }
        #TODO: deep merge, can we automate this somehow ?
        _relation_options[:injected_options][:collection] = (_relation_options[:collection] || {}).merge(
          name: relation.name
        )

        return _relation_options
      end

      def renderer_klass_for(relation)
        renderer = SimpleAMS::Document
        collection_renderer = renderer::Folder

        relation.collection? ? collection_renderer : renderer
      end

=begin TODO: Add that as public method, should help performance in edge cases
      def relationship_info_for(name)
        relations.find{|i| i.name == name}
      end
=end
  end
end
