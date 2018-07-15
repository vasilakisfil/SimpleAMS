require "simple_ams"

#TODO: add initializer to initialize instance vars ?
module SimpleAMS::DSL
  def self.included(host_class)
    host_class.extend ClassMethods
  end

  module ClassMethods
    #same for other ValueHashes
    def adapter(name = nil, options = {})
      @adapter ||= [SimpleAMS::Adapters::DEFAULT, {}]
      return @adapter if name.nil?

      @adapter = [name, options]
    end

    def primary_id(value = nil, options = {})
      @primary_id ||= [:id, {}]
      return @primary_id if value.nil?

      @primary_id = [value || :id, options]
    end

    def type(value = nil, options = {})
      @type ||= [self.to_s.gsub('Serializer','').downcase.split('::').last.to_sym, {}]
      return @type if value.nil?

      @type = [value, options]
    end

    def attributes(*args)
      @attributes ||= []
      return @attributes if (args&.empty? || args.nil?)

      append_attributes(args)
    end
    alias attribute attributes
    alias fields attributes

    def has_many(name, options = {})
      append_relationship([name, __method__, options])
    end

    def has_one(name, options = {})
      append_relationship([name, __method__, options])
    end

    def belongs_to(name, options = {})
      append_relationship([name, __method__, options])
    end

    def relationships
      @relationships || []
    end

    #TODO: there is no memoization here!
    #Consider fixing it by employing an observer that will clean the instance var
    #each time @relationships is updated
    def includes
      relationships.map(&:first)
    end

    def link(name, value, options = {})
      append_link([name, value, options])
    end

    def meta(name = nil, value = nil, options = {})
      append_meta([name, value, options])
    end

    #TODO: Add block version
    def links
      @links || []
    end

    #TODO: Add block version
    #that's not valid spelling..
    def metas
      @metas || []
    end

    def options
      {
        adapter: adapter,
        primary_id: primary_id,
        type: type,
        fields: fields,
        relationships: relationships,
        includes: includes,
        links: links,
        metas: metas
      }
    end

    private
      def append_relationship(rel)
        @relationships ||= []

        @relationships << rel
      end

      def append_attributes(*attrs)
        @attributes ||= []

        @attributes = (@attributes << attrs).flatten.compact
      end

      def append_link(link)
        @links ||= []

        @links << link
      end

      def append_meta(meta)
        @metas ||= []

        @metas << meta
      end
  end
end
