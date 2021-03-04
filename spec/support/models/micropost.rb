require 'spec_helper'

class Micropost
  class << self
    def model_attributes
      @model_attributes ||= instance_methods(false)
    end
  end

  def id
    @id ||= rand(100_000)
  end

  def content
    @content ||= Faker::Lorem.paragraph
  end

  def created_at
    @created_at ||= Faker::Date.backward(days: 100)
  end

  def updated_at
    @updated_at ||= Faker::Date.between(from: created_at, to: Date.today)
  end

  def published_at
    @published_at ||= Faker::Date.between(from: updated_at, to: Date.today)
  end

  def likes_count
    @likes_count ||= rand(100)
  end

  class SubMicropost < self
  end
end
