require 'spec_helper'

class Address
  class << self
    def model_attributes
      @model_attributes ||= instance_methods(false)
    end
  end

  def id
    @id ||= rand(100_000)
  end

  def street_name
    @street_name ||= Faker::Address.street_name
  end

  def street_number
    @street_number ||= rand(100)
  end

  def city
    @city ||= Faker::Address.city
  end

  def post_code
    @post_code ||= Faker::Address.postcode
  end

  def state
    @state ||= Faker::Address.state
  end

  def country
    @country ||= Faker::Address.country
  end

  def created_at
    @created_at ||= Faker::Date.backward(days: 100)
  end

  def updated_at
    @updated_at ||= Faker::Date.between(from: created_at, to: Date.today)
  end

  class SubAddress < self
  end
end
