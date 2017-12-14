require "simple_ams"

module SimpleAMS::DSL
  def self.included(host_class)
    host_class.extend ClassMethods
  end

  module ClassMethods
    def attributes(*args)
      if args&.empty? || args.nil?
        return @attributes
      end

      append_attributes(args)
    end
    alias attribute attributes

    def relationship(name, relation, options)
      SimpleAMS::Relationship::Info.new(name, relation, options)
    end

    def has_many(name, options = {})
      append_relationship(relationship(name, __method__, options))
    end
    alias has_one has_many
    alias belongs_to has_many

    def adapter(name = nil, options = {})
      @adapter ||= {name: name, options: options}
    end

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
