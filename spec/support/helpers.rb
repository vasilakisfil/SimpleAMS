module Helpers
  def self.pick(array, length: nil, min: 0)
    _array = if length
               array.sample(length)
             else
               array.sample(rand(array.length + min))
             end
    _array.sort_by(&array.method(:index))
  end

  def self.recursive_sort(array)
    array.sort_by { |element|
      if element.is_a?(Hash)
        element = { element.keys.first => recursive_sort(element.values) }
        element.keys.first
      else
        element
      end
    }
  end

  def self.initialize_with_overrides(serializer_klass, allowed: nil)
    model_klass = Object.const_get(serializer_klass.to_s.gsub("Serializer", ""))
    overrides = Helpers.pick(allowed || model_klass.model_attributes)
    serializer_klass.with_overrides(overrides)
    serializer_klass.attributes(*(allowed || model_klass.model_attributes))

    overrides
  end

  def self.reset!(*resources)
    resources = [resources].flatten

    resources.each do |resource|
      resource.relations.each { |r|
        next unless r.last.to_s.include?('Embedded')

        begin
          resource.send(:remove_const, r.last.to_s.split('::').last)
        rescue NameError => _e
          #ignore
        end
      }

      [
        :attributes, :relations, :links, :metas, :adapter, :primary_id, :type,
        :collection, :forms, :generics
      ].each do |var|
        resource.remove_instance_variable("@_#{var}") if resource.instance_variable_defined?("@_#{var}")

        resource::Collection_.remove_instance_variable("@_#{var}") if resource::Collection_.instance_variable_defined?("@_#{var}")
      end

      model = const_get(resource.to_s.split("::").last.gsub('Serializer', ''))
      relations = model.respond_to?(:relations) ? model.relations : []
      relations.map(&:name).each do |name|
        if const_defined?("#{resource}::Embedded#{name.capitalize}Options_")
          resource.send(:remove_const, "Embedded#{name.capitalize}Options_")
        end
      end
    end
  end

  #not that random..
  def self.random_options(with: {}, without: [])
    options = {
      type: :user,
      primary_id: :id,
      includes: Helpers.pick(User.relation_names),
      fields: Helpers.pick(User.model_attributes),
      links: {
        self: "/api/v1/#{Faker::Lorem.word}/#{rand(1000)}",
        posts: [
          "/api/v1/#{Faker::Lorem.word}/#{rand(1000)}/#{Faker::Lorem.word}/",
          { collection: [false, true].sample }
        ]
      },
      metas: Options.hash,
      collection: {
        links: {
          root: '/api/v1/',
          documentation: '/api/documentation', foobar: [:yes, :no].sample,
          status: ->(obj, _s) { ["/status/#{obj.hash}"] }
        },
        meta: Options.hash
      }
    }.merge(with)

    without.each { |s| options.delete(s) }

    options
  end

  def self.random_relations_with_types
    User.relations.each_with_object({}) { |relation, memo|
      memo[relation.name] = relation.type
    }
  end

  class Options
    class << self
      undef :hash

      def method_missing(meth, *args)
        if self.new.respond_to? meth
          self.new.send(meth, *args)
        else
          super
        end
      end
    end

    def single
      Faker::Lorem.word.to_sym
    end

    def array(deep: false)
      if deep
        deep_array
      else
        random_array
      end
    end

    def hash(deep: false)
      if deep
        deep_hash
      else
        random_hash
      end
    end

    private

    def random_array
      rand(10).times.map {
        coin = rand(10) / 10.to_f
        if coin >= 0.9
          { single => random_array }
        else
          single
        end
      }
    end

    def deep_array
      array.concat(
        [{ single => random_array }]
      ).flatten
    end

    def random_hash
      rand(10).times.inject({}) do |memo|
        coin = rand(10) / 10.to_f
        memo[single] = if coin >= 0.9
                         hash
                       else
                         single
                       end

        memo
      end
    end

    def deep_hash
      random_hash.merge(single => random_hash)
    end
  end

  class Adapter1; end
  class Adapter2; end

  #no idea why Singleton is not working, but probably has to do with RSpec
  #(NameError: uninitialized constant Singleton)
  def self.define_singleton_for(name, opts = {})
    _klass = Class.new(Object) do
      opts.keys.each do |key|
        define_singleton_method(key) do
          opts[key]
        end
      end
    end

    const_set(name, _klass)
  end
end
