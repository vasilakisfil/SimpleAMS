require "simple_ams"

module SimpleAMS::DSL
  def self.included(host_class)
    host_class.extend ClassMethods
  end

  module ClassMethods
    #TODO: raise error if options are given outside `options` key
    #same for other ValueHashes
    def adapter(name = nil, options = {})
      @adapter ||= SimpleAMS::Options::Adapter.new(name || :ams, options)
    end

    def primary_id(value = nil)
      @primary_id ||= SimpleAMS::Options::PrimaryId.new(value || :id)
    end

    def attributes(*args)
      if args&.empty? || args.nil?
        return @attributes ||= SimpleAMS::Options::Fields.new([])
      end

      append_attributes(args)
    end
    alias attribute attributes

    def relationship(name, relation, options)
      SimpleAMS::Options::Relation.new(name, relation, options)
    end

    def has_many(name, options = {})
      append_relationship(relationship(name, __method__, options))
    end

    def has_one(name, options = {})
      append_relationship(relationship(name, __method__, options))
    end

    def belongs_to(name, options = {})
      append_relationship(relationship(name, __method__, options))
    end

    def relationships
      @relationships || []
    end

    #TODO: no memoization here!
    #Consider fixing it by employing an observer that will clean the instance var
    #each time @relationships is updated
    def includes
      SimpleAMS::Options::Includes.new(relationships.map(&:name))
    end

    def link(name, value, options = {})
      append_link(name => [value, options])
    end

    def meta(name = nil, value = nil, options = {})
      if name == nil
        return @meta
      else
        #TODO: should it check empty value ?
        append_meta(name => [value, options])
      end
    end

    #TODO: Add block version
    def links
      @links
    end

    private
      def append_relationship(rel)
        @relationships = [] unless defined?(@relationships)

        @relationships << rel
      end

      def append_attributes(*attrs)
        if not defined?(@attributes)
          @attributes = SimpleAMS::Options::Fields.new([])
        end

        @attributes = SimpleAMS::Options::Fields.new(
          (@attributes << attrs).flatten.compact
        )
      end

      def append_link(link)
        @links = [] unless defined?(@links)

        @links << link
      end

      def append_meta(meta)
        @meta = [] unless defined?(@meta)

        @meta << meta
      end
  end
end
