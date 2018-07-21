require 'spec_helper'

class Micropost
  class << self
    def model_attributes
      @attributes ||= self.instance_methods(false)
    end
  end

  def id
    @id ||= rand(100000)
  end

  def content
    @content ||= Faker::Lorem.paragraph
  end

  def created_at
    @cretated_at ||= Faker::Date.backward(100)
  end

  def updated_at
    @updated_at ||= Faker::Date.between(created_at, Date.today)
  end

  def published_at
    @published_at ||= Faker::Date.between(updated_at, Date.today)
  end

  def likes_count
    @likes_count ||= rand(100)
  end

  class SubMicropost < self
  end
end
