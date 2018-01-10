require 'spec_helper'

class User
  class << self
    def model_attributes
      @attributes ||= User.instance_methods(false)
    end

    def model_relations
      @relations ||= []
    end
  end

  def id
    @id ||= rand(100000)
  end

  def name
    @name ||= Faker::Name.name
  end

  def email
    @email ||= Faker::Internet.email
  end

  def admin
    @admin ||= [false, true].sample
  end

  def created_at
    @cretated_at ||= Faker::Date.backward(100)
  end

  def updated_at
    @updated_at ||= Faker::Date.between(created_at, Date.today)
  end

  def token
    @token ||= SecureRandom.hex
  end

  def followers_count
    @followers_count ||= random(100)
  end

  def followings_count
    @followers_count ||= random(100)
  end

  def microposts_count
    @microposts_count ||= random(100)
  end
end
