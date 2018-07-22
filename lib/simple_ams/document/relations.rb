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
        SimpleAMS::Renderer.new(
          relation_value(relation.name),
          #TODO: this part here needs some work
          #4 options are merged:
          # *user injected when instantiating the SimpleAMS class
          # *relation options injected from parent serializer
          # *serializer class options
          SimpleAMS::Options.new(relation_value(relation.name), {
            injected_options: (relation.options || {}).merge(
              options.relation_options_for(relation.name).merge(expose: options.expose)
            ).merge(
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

      def relationship_info_for(name)
        relations.find{|i| i.name == name}
      end

=begin
      #merges the injected, along with the parent serializer injected options
      #probably needs better work, maybe exploit existing Options class?
      def merged_options(parent_options, injected_options, relation_name)
        #does this really work for deep deep options?
        _options = {}

        (injected_options.keys + parent_options.keys).each do |key|
          next if parent_options[key].nil? && injected_options[key].nil?

          if parent_options[key].kind_of?(Hash) || injected_options[key].kind_of?(Hash)
            _options[key] = (parent_options[key] || {}).merge(injected_options[key] || {})
          elsif parent_options[key].kind_of?(Array) || injected_options[key].kind_of?(Array)
            _options[key] = (parent_options[key] || []) & (injected_options[key] || [])
          elsif key == :name
            _options[key] = (parent_options[key] || injected_options[key])
          else
            _options[key] = (parent_options[key] || injected_options[key])
          end
        end

        _options[:name] ||= relation_name
        return _options
      end
=end
  end
end
