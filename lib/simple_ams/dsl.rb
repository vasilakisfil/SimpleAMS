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
          forms: forms,
          generics: generics,
        }
      end
    end

    host_class.const_set('Collection_', _klass)
  end

  module ClassMethods
    #TODO: Shouldn't we call here super to presever user's behavior ?
    def inherited(subclass)
      #TODO: why this breaks collection type?
      subclass.with_options(
        options.merge(
          #TODO: maybe add another group of elements under dsl?
          #this could be DSL::Type.new(type).explicit?
          type.last[:_explicit] ? {} : {type: nil}
        )
      )

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
            forms: forms,
            generics: generics,
          }
        end
      end

      subclass.const_set('Collection_', _klass)
    end

    def default_options
      @_default_options ||= {
        adapter: [SimpleAMS::Adapters::AMS, {}],
        primary_id: [:id, {}],
        type: [_default_type_name, {}]
      }
    end

    #TODO: Add tests !!
    def _default_type_name
      if self.to_s.end_with?('::Collection_')
        _name = self.to_s.gsub(
          'Serializer',''
        ).gsub(
          '::Collection_', ''
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
        if key == :relations
          (value || []).each{|rel_value|
            append_relationship(rel_value)
          }
        elsif key.to_sym == :collection
          #TODO: Add proc option maybe?
          if value.is_a?(Hash)
            collection{}.with_options(value)
          end
        elsif meths.include?(key)
          if (value.is_a?(Array) && value.first.is_a?(Array)) || value.is_a?(Hash)
            self.send(key, value)
          else
            self.send(key, *value)
          end
        else
          #TODO: Add a proper logger
          puts "SimpeAMS: #{key} is not recognized, ignoring (from #{self.to_s})"
        end
      end

      return @_options
    end

    def adapter(value = nil, options = {})
      @_adapter = _value_hash_for(@_adapter, value, options, :adapter)
    end

    def primary_id(value = nil, options = {})
      @_primary_id = _value_hash_for(@_primary_id, value, options, :primary_id)
    end

    def type(value = nil, options = {})
      @_type = _value_hash_for(@_type, value, options.merge(_explicit: true), :type)
    end

    def attributes(*args)
      @_attributes ||= []
      return @_attributes.uniq if (args&.empty? || args.nil?)

      append_attributes(args)
    end
    alias attribute attributes
    alias fields attributes

    def attributes=(*args)
      @_attributes = []

      attributes(args)
    end

    def has_many(name, options = {}, &block)
      append_relationship(
        [__method__, name, options, embedded_class_for(name, options, block)]
      )
    end

    def has_one(name, options = {}, &block)
      append_relationship(
        [__method__, name, options, embedded_class_for(name, options, block)]
      )
    end

    def belongs_to(name, options = {}, &block)
      append_relationship(
        [__method__, name, options, embedded_class_for(name, options, block)]
      )
    end

    def relations
      @_relations || []
    end

    def embedded_class_for(name, options, block)
      embedded = Class.new(self)
      klass_name = "Embedded#{name.to_s.capitalize}Options_"
      self.const_set(klass_name, embedded)
      embedded.with_options(
        default_options.merge(options.select{|k| k != :serializer})
      )
      embedded.instance_exec(&block) if block

      return embedded
    end

    #TODO: there is no memoization here, hence we ignore includes manually set !!
    #Consider fixing it by employing an observer that will clean the instance var
    #each time @_relations is updated
    def includes(*args)
      relations.map{|rel| rel[1] }
    end

    def link(name, value, options = {})
      append_link([name, value, options])
    end

    def meta(name = nil, value = nil, options = {})
      append_meta([name, value, options])
    end

    def form(name, value, options = {})
      append_form([name, value, options])
    end

    def generic(name, value, options = {})
      append_generic([name, value, options])
    end

    def links(links = [])
      return @_links ||= [] if links.empty?
      links.map{|key, value| append_link([key, value].flatten(1))} if links.is_a?(Hash)

      @_links ||= links
    end

    def metas(metas = [])
      return @_metas ||= [] if metas.empty?

      metas.map{|key, value| append_meta([key, value].flatten(1))} if metas.is_a?(Hash)

      @_metas ||= metas
    end

    def forms(forms = [])
      return @_forms ||= [] if forms.empty?
      forms.map{|key, value| append_form([key, value].flatten(1))} if forms.is_a?(Hash)

      @_forms ||= forms
    end

    def generics(generics = [])
      return @_generics ||= [] if generics.empty?
      generics.map{|key, value| append_generic([key, value].flatten(1))} if generics.is_a?(Hash)

      @_generics ||= generics
    end

    def collection(name = nil, &block)
      if block
        self::Collection_.class_eval do
          instance_exec(&block)
        end
      end

      self::Collection_.type(name) if name

      return self::Collection_
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
        forms: forms,
        generics: generics,
        collection: collection
      }
    end

    def simple_ams?
      true
    end

    private
      def _value_hash_for(current, value, options, name)
        _type = current || default_options[name]
        return _type if value.nil?

        return [value, options]
      end

      def append_relationship(rel)
        @_relations ||= []

        @_relations << rel
      end

      def append_attributes(*attrs)
        @_attributes ||= []

        @_attributes = (@_attributes << attrs).flatten.compact.uniq
      end

      def append_link(link)
        @_links ||= []

        @_links << link
      end

      def append_meta(meta)
        @_metas ||= []

        @_metas << meta
      end

      def append_form(form)
        @_forms ||= []

        @_forms << form
      end

      def append_generic(generic)
        @_generics ||= []

        @_generics << generic
      end

      def empty_options
      end
  end
end
