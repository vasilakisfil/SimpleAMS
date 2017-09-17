require "simple_ams"

module SimpleAMS::DSL
  def self.included(host_class)
    host_class.extend ClassMethods
    host_class.include InstanceMethods
  end

  module InstanceMethods
    def initialize(resource, options = {})
      @resource, @options = resource, options
    end

    def model
      @model ||= SimpleAMS::Model.new(self, @options)
    end

    def as_json
      model.adapter.new(SimpleAMS::Decorator.new(model, @resource)).as_json
    end

    def to_json
      as_json.to_json
    end
  end

  module ClassMethods
    def attributes(*args)
      if args&.empty? || args.nil?
        return @attributes
      end

      append_attributes(args)
    end

    def relationship(name, relation, options)
      SimpleAMS::Relationship.new(name, relation, options)
    end

    def has_many(name, options = {})
      append_relationship(relationship(name, __method__, options))
    end
    alias has_one has_many
    alias belongs_to has_many

    def relationships
      @relationships || []
    end

    private
      def append_relationship(rel)
        @relationships = [] unless defined?(@relationships)

        @relationships << rel
      end

      def append_attributes(*attrs)
        @attributes = [] unless defined?(@attributes)

        @attributes = (@attributes << attrs).flatten.compact
      end
  end
end
