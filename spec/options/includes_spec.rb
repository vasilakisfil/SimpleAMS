require "spec_helper"

RSpec.describe SimpleAMS::Options, "includes" do
  context "with no reations in general" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
        }).tap{|h|
          h.delete(:includes)
        }
      })
    end

    it "returns empty array" do
      expect(@options.relations).to eq []
    end
  end

  context "with no injected includes" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      @allowed_relations.each do |rel, type|
        UserSerializer.send(type, rel, Helpers.random_options)
      end
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
        }).tap{|h| h.delete(:includes)}
      })
    end

    it "holds the specified options" do
      expect(@options.relations.map(&:name)).to(
        eq(
          @allowed_relations.keys
        )
      )
    end
  end

  context "with empty injected includes" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      @allowed_relations.each do |rel, type|
        UserSerializer.send(type, rel, Helpers.random_options)
      end
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
          includes: []
        })
      })
    end

    it "holds the specified options" do
      expect(@options.relations.available).to(
        eq(
          []
        )
      )
    end
  end

  context "with various includes" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      @allowed_relations.each do |rel, type|
        UserSerializer.send(type, rel, Helpers.random_options)
      end
      @injected_relations = Helpers.pick(@allowed_relations.keys)
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          includes: @injected_relations
        })
      })
    end

    it "holds the specified options" do
      expect(@options.relations.available.map(&:name)).to(
        eq(
          @allowed_relations.keys & @injected_relations
        )
      )
    end
  end

  context "with repeated includes" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      2.times {
        @allowed_relations.each do |rel, type|
          UserSerializer.send(type, rel, Helpers.random_options)
        end
      }
      @injected_relations = Helpers.pick(@allowed_relations.keys)
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          includes: @injected_relations
        })
      })
    end

    it "holds the uniq union of injected and allowed includes" do
      expect(@options.includes).to(
        eq(
          (@allowed_relations.keys & @injected_relations).uniq
        )
      )
    end
  end
end
