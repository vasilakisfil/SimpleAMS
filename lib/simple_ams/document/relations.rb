require 'simple_ams'

# TODO: Add memoization for the relations object (iteration + access)
class SimpleAMS::Document::Relations
  include Enumerable

  def initialize(options, relations)
    @options = options
    @relations = relations
    @serializer = options.serializer
    @resource = options.resource
  end

  def [](key)
    found = relations.find { |relation| relation.name == key }
    return nil unless found

    relation_for(found)
  end

  def each
    return enum_for(:each) unless block_given?

    relations.each do |relation|
      yield relation_for(relation)
    end

    self
  end

  def empty?
    relations.length.zero?
  end

  def available
    return @available ||= [] if relations.available.empty?

    @available ||= self.class.new(options, relations.available)
  end

  private

  attr_reader :options, :relations, :serializer, :resource

  def relation_for(relation)
    relation_value = relation_value_for(relation.name)

    renderer_klass_for(relation, relation_value).new(
      SimpleAMS::Options.new(
        relation_value, relation_options_for(relation, relation_value)
      ),
      SimpleAMS::Options.new(
        resource, {
          injected_options: {
            serializer: relation.embedded
          },
          allowed_options: relation.embedded.options
        }
      )
    )
  end

  # TODO: rename that to relation and existing relation to relationship
  def relation_value_for(name)
    if serializer.respond_to?(name)
      serializer.send(name)
    else
      resource.send(name)
    end
  end

  # 4 options are merged:
  # *user injected when instantiating the SimpleAMS class
  # *relation options injected from parent serializer
  # *serializer class options
  # rubocop:disable Lint/UnderscorePrefixedVariableName
  def relation_options_for(relation, relation_value)
    _relation_options = {
      injected_options: (relation.options || {}).merge(
        options.relation_options_for(
          relation.name
        ).reject { |_k, v| v.nil? }.merge(
          expose: options.expose
        )
      ).merge(
        _internal: {
          module: serializer.class.to_s.rpartition('::')[0]
        }
      )
    }

    if relation.collection? || relation_value.respond_to?(:each)
      # TODO: deep merge, can we automate this somehow ?
      _relation_options[:injected_options][:collection] = {
        name: relation.name
      }.merge(_relation_options[:injected_options][:collection] || {})
    else
      _relation_options[:injected_options][:name] = relation.name
    end

    _relation_options
  end
  # rubocop:enable Lint/UnderscorePrefixedVariableName

  def renderer_klass_for(relation, relation_value)
    return SimpleAMS::Document::Folder if relation.collection?
    return SimpleAMS::Document::Folder if relation_value.respond_to?(:each)

    SimpleAMS::Document
  end

  # TODO: Add that as public method, should help performance in edge cases
  #       def relationship_info_for(name)
  #         relations.find{|i| i.name == name}
  #       end
end
