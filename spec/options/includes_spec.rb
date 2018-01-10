require "spec_helper"

RSpec.describe "SimpleAMS::Options#includes" do
  context "with no includes in general" do
    before do
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer
        }).tap{|h| h.delete(:includes)}
      )
    end

    it "returns an empty array" do
      expect(@options.includes).to eq []
    end
  end

  context "with no injected includes" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      @allowed_relations.each do |rel, type|
        UserSerializer.send(type, rel, options: Helpers.random_options)
      end
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
        }).tap{|h| h.delete(:includes)}
      )
    end

    it "holds the specified options" do
      expect(@options.includes).to eq @allowed_relations.keys.uniq
    end
  end

  context "with empty injected includes" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      @allowed_relations.each do |rel, type|
        UserSerializer.send(type, rel, options: Helpers.random_options)
      end
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
          includes: []
        })
      )
    end

    it "holds the specified options" do
      expect(@options.includes).to(
        eq(
          []
        )
      )
    end
  end

  context "with no allowed includes but injected ones" do
    before do
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
        })
      )
    end

    it "returns empty links array" do
      expect(@options.includes).to eq []
    end
  end

  context "with various injected includes" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      @allowed_relations.each do |rel, type|
        UserSerializer.send(type, rel, options: Helpers.random_options)
      end
      @injected_relations = @allowed_relations.keys.sample(
        0#rand(@allowed_relations.keys.length)
      )
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
          includes: @injected_relations
        })
      )
    end

    it "holds the specified options" do
      expect(@options.includes).to(
        eq(
          (@allowed_relations.keys & @injected_relations).uniq
        )
      )
    end
  end

  context "with repeated includes" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      2.times {
        @allowed_relations.each do |rel, type|
          UserSerializer.send(type, rel, options: Helpers.random_options)
        end
      }
      @injected_relations = @allowed_relations.keys.sample(
        0#rand(@allowed_relations.keys.length)
      )
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
          includes: @injected_relations
        })
      )
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
