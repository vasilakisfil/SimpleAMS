module Helpers
  def self.reset!(resource)
    [:@attributes, :@relationships, :@links, :@metas, :@adapter, :@primary_id, :@type].each do |var|
      if resource.instance_variable_defined?(var)
        resource.remove_instance_variable(var)
      end
    end
  end

  def self.random_options
    {
      type: :user,
      primary_id: Options.single,
      includes: Options.array,
      fields: Options.array,
      links: {
        self: "/api/v1/users/1",
        posts: ["/api/v1/users/1/posts/", options: {collection: true}]
      },
      meta: Options.hash,
      collection: {
        links: {
          root: '/api/v1/'
        },
        meta: Options.hash
      }
    }
  end

  def self.random_options_with(opts = {})
    options = random_options
    return options.merge(opts)
  end

  #not that random..
  def self.random_relations_with_types
    {
      microposts: :has_many,
      followers: :has_many,
      followings: :has_many,
      unit: :belongs_to,
      area: :belongs_to,
      address: :has_one,
      house: :has_one
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
end
