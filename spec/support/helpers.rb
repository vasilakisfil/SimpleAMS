module Helpers
  def self.pick(array, length: nil, min: 0)
    if length
    _array = array.sample(length)
    else
    _array = array.sample(rand(array.length + min))
    end
    _array.sort_by(&array.method(:index))
  end

  def self.recursive_sort(array)
    array.sort_by{|element|
      if element.is_a?(Hash)
        element = {element.keys.first => recursive_sort(element.values)}
        element.keys.first
      else
        element
      end
    }
  end

  def self.initialize_with_overrides(serializer_klass, allowed: nil)
    model_klass = Object.const_get(serializer_klass.to_s.gsub("Serializer",""))
    overrides = Helpers.pick(allowed || model_klass.model_attributes)
    serializer_klass.with_overrides(overrides)
    serializer_klass.attributes(*(allowed || model_klass.model_attributes))

    return overrides
  end

  def self.reset!(*resources)
    resources = [resources].flatten

    resources.each do |resource|
      [
        :attributes, :relations, :links, :metas, :adapter, :primary_id, :type,
        :collection, :forms
      ].each do |var|
        if resource.instance_variable_defined?("@_#{var}")
          resource.remove_instance_variable("@_#{var}")
        end
        
        if resource::Collection_.instance_variable_defined?("@_#{var}")
          resource::Collection_.remove_instance_variable("@_#{var}")
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
          collection: [false, true].sample
        ]
      },
      metas: Options.hash,
      collection: {
        links: {
          root: '/api/v1/',
          documentation: '/api/documentation', foobar: [:yes, :no].sample,
          status: ->(obj){["/status/#{obj.hash}"]}
        },
        meta: Options.hash
      }
    }.merge(with)

    without.each{|s| options.delete(s)}

    return options
  end

  def self.random_relations_with_types
    User.relations.inject({}){|memo, relation|
      memo[relation.name] = relation.type
      memo
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
        rand(10).times.map{
          coin = rand(10)/10.to_f
          if coin >= 0.9
            {single => random_array}
          else
            single 
          end
        }
      end

      def deep_array
        array.concat(
          [{single => random_array}]
        ).flatten
      end

      def random_hash
        rand(10).times.inject({}){|memo|
          coin = rand(10)/10.to_f
          if coin >= 0.9
            memo[single] = hash
          else
            memo[single] = single
          end

          memo
        }
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
