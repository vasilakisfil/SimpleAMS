require "simple_ams"

module SimpleAMS::DSL
  def self.included(host_class)
    host_class.extend ClassMethods

    _klass = Class.new(Object).extend(ClassMethods)
    _klass.instance_eval do
      def options
        {
          adapter: adapter,
          primary_id: primary_id,
          type: type,
          fields: fields,
          relations: relations,
          includes: includes,
          links: links,
          metas: metas,
        }
      end
    end

    host_class.const_set('Collection', _klass)
  end

  module ClassMethods
    def default_options
      @_default_options ||= {
        adapter: [SimpleAMS::Adapters::AMS, {}],
        primary_id: [:id, {}],
        type: [_default_type_name, {}]
      }
    end

    #TODO: Add tests !!
    def _default_type_name
      if self.to_s.end_with?('::Collection')
        _name = self.to_s.gsub(
          'Serializer',''
        ).gsub(
          '::Collection', ''
        ).downcase.split('::').last

        return "#{_name}_collection".to_sym
      else
        return self.to_s.gsub('Serializer','').downcase.split('::').last.to_sym
      end
    end
    def with_options(options = {})
      @_options = options
      meths = SimpleAMS::DSL::ClassMethods.instance_methods(false)
      @_options.each do |key, value|
        if key.to_sym == :collection
          self.send(:collection){}.with_options(value)
        elsif meths.include?(key)
          self.send(key, value) if value.is_a?(Array)
          self.send(key, value)
        else
          #TODO: Add a proper logger
          puts "SimpeAMS: #{key} is not recognized, ignoring (from #{self.to_s})"
        end
      end

      return @_options
    end

    #same for other ValueHashes
    def adapter(name = nil, options = {})
      @_adapter ||= default_options[:adapter]
      return @_adapter if name.nil?

      @_adapter = [name, options]
    end

    def primary_id(value = nil, options = {})
      @_primary_id ||= default_options[:primary_id]
      return @_primary_id if value.nil?

      @_primary_id = [value, options]
    end

    def type(value = nil, options = {})
      @_type ||= default_options[:type]
      return @_type if value.nil?

      @_type = [value, options]
    end

    def attributes(*args)
      @_attributes ||= []
      return @_attributes.uniq if (args&.empty? || args.nil?)

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
      @_relations || []
    end

    #TODO: there is no memoization here, hence we ignore includes manually set !!
    #Consider fixing it by employing an observer that will clean the instance var
    #each time @_relations is updated
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

      @_links ||= links
    end

    def metas(metas = [])
      metas.map{|key, value| append_meta([key, value].flatten(1))} if metas.is_a?(Hash)

      @_metas || []
    end

    def collection(name = nil, &block)
      if block
        self::Collection.class_eval do
          instance_exec(&block)
        end
      end

      self::Collection.type(name) if name

      return self::Collection
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
        metas: metas,
        collection: collection
      }
    end

    private
      def append_relationship(rel)
        @_relations ||= []

        @_relations << rel
      end

      def append_attributes(*attrs)
        @_attributes ||= []

        @_attributes = (@_attributes << attrs).flatten.compact
      end

      def append_link(link)
        @_links ||= []

        @_links << link
      end

      def append_meta(meta)
        @_metas ||= []

        @_metas << meta
      end

      def empty_options
      end
  end
end
