require "simple_ams"

#TODO: add initializer to initialize instance vars ?
module SimpleAMS::DSL
  def self.included(host_class)
    host_class.extend ClassMethods
  end

  module ClassMethods
    def default_options
      @default_options ||= {
        adapter: [SimpleAMS::Adapters::DEFAULT, {}],
        primary_id: [:id, {}],
        type: [self.to_s.gsub('Serializer','').downcase.split('::').last.to_sym, {}]
      }
    end
    def with_options(options = {})
      @options = options
      meths = SimpleAMS::DSL::ClassMethods.instance_methods(false)
      @options.each do |key, value|
        if meths.include?(key)
          self.send(key, *value) if value.is_a?(Array)
          self.send(key, value)
        else
          #TODO: Add a proper logger
          puts "SimpeAMS: #{key} is not recognized, ignoring (from #{self.to_s})"
        end
      end

      return @options
    end

    #same for other ValueHashes
    def adapter(name = nil, options = {})
      @adapter ||= default_options[:adapter]
      return @adapter if name.nil?

      @adapter = [name, options]
    end

    def primary_id(value = nil, options = {})
      @primary_id ||= default_options[:primary_id]
      return @primary_id if value.nil?

      @primary_id = [value, options]
    end

    def type(value = nil, options = {})
      @type ||= default_options[:type]
      return @type if value.nil?

      @type = [value, options]
    end

    def attributes(*args)
      @attributes ||= []
      return @attributes.uniq if (args&.empty? || args.nil?)

      append_attributes(args)
    end
    alias attribute attributes
    alias fields attributes

    def has_many(name, options = {})
      append_relationship([__method__, name, options])
    end

    def has_one(name, options = {})
      append_relationship([__method__, name, options])
    end

    def belongs_to(name, options = {})
      append_relationship([__method__, name, options])
    end

    def relations
      @relations || []
    end

    #TODO: there is no memoization here, hence we ignore includes manually set !!
    #Consider fixing it by employing an observer that will clean the instance var
    #each time @relations is updated
    def includes(_ = [])
      relations.map{|rel| rel[1] }
    end

    def link(name, value, options = {})
      append_link([name, value, options])
    end

    def meta(name = nil, value = nil, options = {})
      append_meta([name, value, options])
    end

    def links(links = [])
      links.map{|key, value| append_link([key, value].flatten(1))} if links.is_a?(Hash)

      @links ||= links
    end

    def metas(metas = [])
      metas.map{|key, value| append_meta([key, value].flatten(1))} if metas.is_a?(Hash)

      @metas || []
    end

    def options
      {
        adapter: adapter,
        primary_id: primary_id,
        type: type,
        fields: fields,
        relations: relations,
        includes: includes,
        links: links,
        metas: metas
      }
    end

    private
      def append_relationship(rel)
        @relations ||= []

        @relations << rel
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
