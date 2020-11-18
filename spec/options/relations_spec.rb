require "spec_helper"

RSpec.describe SimpleAMS::Options, "relations" do
  context "with no reations in general" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap { |h|
          h.delete(:includes)
          h.delete(:relations)
        }
      })
    end

    it "returns empty array" do
      expect(@options.relations).to eq []
    end
  end

  context "with no injected relations" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      @allowed_relations.each do |rel, type|
        UserSerializer.send(type, rel, Helpers.random_options)
      end
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap { |h| h.delete(:includes) }
      })
    end

    it "holds the specified options" do
      expect(@options.relations.map(&:name)).to(
        eq(
          @allowed_relations.keys
        )
      )
      expect(@options.relations.map(&:single?)).to(
        eq(
          @allowed_relations.values.map { |t|
            t == :has_many ? false : true
          }
        )
      )
    end
  end

  context "with empty injected relations" do
    before do
      @allowed_relations = Helpers.random_relations_with_types
      @allowed_relations.each do |rel, type|
        UserSerializer.send(type, rel, Helpers.random_options)
      end
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          relations: []
        })
      })
    end

    it "holds the specified options" do
      expect(@options.relations).to(
        eq(
          []
        )
      )
    end
  end

  context "with injected relations but empty includes" do
    before do
      @injected_relations = User.relations.map do |relation|
        [relation.type, relation.name, Helpers.random_options]
      end
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          relations: @injected_relations
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

  context "with injected relations and related includes but no allowed includes" do
    before do
      @injected_relations = User.relations.map do |relation|
        [relation.type, relation.name, Helpers.random_options]
      end
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          relations: @injected_relations,
          includes: @injected_relations.map { |relation| relation[1] }
        })
      })
    end

    it "holds the specified options" do
      expect(@options.relations.available).to(
        eq([])
      )
    end
  end

  context "with injected relations that override allowed relations" do
    before do
      @injected_relation_options = Helpers.random_options
      @injected_relations = User.relations.map do |relation|
        [relation.type, relation.name, @injected_relation_options, nil]
      end
      @injected_relations.each do |relation_array|
        type = relation_array[0]
        name = relation_array[1]
        UserSerializer.send(type, name, Helpers.random_options)
      end
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
          relations: @injected_relations,
        }, without: [:includes])
      })
    end

    it "holds the specified options" do
      expect(@options.relations.map(&:raw)).to(
        eq(@injected_relations)
      )
    end
  end

  context "with injected relations that override allowed relations but empty injected includes" do
    before do
      @injected_relation_options = Helpers.random_options
      @injected_relations = User.relations.map do |relation|
        [relation.type, relation.name, @injected_relation_options]
      end
      @injected_relations.each do |relation_array|
        type = relation_array[0]
        name = relation_array[1]
        UserSerializer.send(type, name, Helpers.random_options)
      end
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
          relations: @injected_relations,
          includes: []
        })
      })
    end

    it "holds the specified options" do
      expect(@options.relations.available).to(
        eq([])
      )
    end
  end
end

