require 'spec_helper'

class User
  class << self
    def model_attributes
      @model_attributes ||= instance_methods(false) - relations.map(&:name)
    end

    def relation_names
      @relation_names ||= relations.map(&:name)
    end

    def relations
      [
        OpenStruct.new(
          type: :has_many, name: :microposts, options: { serializer: MicropostSerializer }
        ),
        OpenStruct.new(
          type: :has_many, name: :followers, options: { serializer: UserSerializer }
        ),
        OpenStruct.new(
          type: :has_many, name: :followings, options: { serializer: UserSerializer }
        ),
        OpenStruct.new(
          type: :has_one, name: :address, options: { serializer: AddressSerializer }
        )
      ]
    end

    def array
      rand(1..10).times.map { new }.send(:extend, Module.new do
        def id
          @id ||= rand(100_000)
        end
      end)
    end
  end

  def initialize(opts = {})
    opts.each_key do |key|
      instance_variable_set("@#{key}", opts[key])
    end
  end

  def id
    @id ||= rand(100_000)
  end

  def name
    @name ||= Faker::Name.name
  end

  def email
    @email ||= Faker::Internet.email
  end

  def admin
    return @admin if defined?(@admin)

    @admin = [false, true].sample
    @admin
  end

  def created_at
    @created_at ||= Faker::Date.backward(100)
  end

  def updated_at
    @updated_at ||= Faker::Date.between(created_at, Date.today)
  end

  def token
    @token ||= SecureRandom.hex
  end

  def followers_count
    @followers_count ||= rand(100)
  end

  def followings_count
    @followings_count ||= rand(100)
  end

  def microposts_count
    @microposts_count ||= rand(100)
  end

  def microposts
    @microposts ||= rand(10).times.map { Micropost.new }
  end

  def followers
    @followers ||= rand(10).times.map { User.new }
  end

  def followings
    @followings ||= rand(10).times.map { User.new }
  end

  def address
    @address ||= Address.new
  end

  class SubUser < self
  end
end
