require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'relations' do
  context "with no relations" do
    it "returns an empty array" do
      expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relationships).to eq []
    end
  end

  #TODO: Add random options generator
  describe "has_many" do
    context "plain" do
      before do
        UserSerializer.has_many(:microposts)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relationships.count).to eq 1
        expect(UserSerializer.relationships.first.name).to eq :microposts
        expect(UserSerializer.relationships.first.array?).to eq true
        expect(UserSerializer.relationships.first.relation).to eq :has_many
      end
    end

    context "with options" do
      before do
        @options = Helpers.random_options
        UserSerializer.has_many(:microposts, options: @options)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relationships.count).to eq 1
        expect(UserSerializer.relationships.first.name).to eq :microposts
        expect(UserSerializer.relationships.first.array?).to eq true
        expect(UserSerializer.relationships.first.relation).to eq :has_many
        expect(UserSerializer.relationships.first.options).to eq @options
      end
    end
  end

  describe "has_one" do
    context "plain" do
      before do
        UserSerializer.has_one(:follower)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relationships.count).to eq 1
        expect(UserSerializer.relationships.first.name).to eq :follower
        expect(UserSerializer.relationships.first.array?).to eq false
        expect(UserSerializer.relationships.first.relation).to eq :has_one
      end
    end

    context "with options" do
      before do
        @options = Helpers.random_options
        UserSerializer.has_one(:follower, options: @options)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relationships.count).to eq 1
        expect(UserSerializer.relationships.first.name).to eq :follower
        expect(UserSerializer.relationships.first.array?).to eq false
        expect(UserSerializer.relationships.first.relation).to eq :has_one
        expect(UserSerializer.relationships.first.options).to eq @options
      end
    end
  end

  describe "belongs_to" do
    context "plain" do
      before do
        UserSerializer.belongs_to(:unit)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relationships.count).to eq 1
        expect(UserSerializer.relationships.first.name).to eq :unit
        expect(UserSerializer.relationships.first.array?).to eq false
        expect(UserSerializer.relationships.first.relation).to eq :belongs_to
      end
    end

    context "with options" do
      before do
        @options = Helpers.random_options
        UserSerializer.belongs_to(:unit, options: @options)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relationships.count).to eq 1
        expect(UserSerializer.relationships.first.name).to eq :unit
        expect(UserSerializer.relationships.first.array?).to eq false
        expect(UserSerializer.relationships.first.relation).to eq :belongs_to
        expect(UserSerializer.relationships.first.options).to eq @options
      end
    end
  end

  describe "combined" do
    context "plain" do
      before do
        @options = Helpers.random_options

        UserSerializer.has_many(:microposts, options: @options)
        UserSerializer.belongs_to(:unit, options: @options)
        UserSerializer.has_one(:follower, options: @options)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relationships.count).to eq 3

        relation = UserSerializer.relationships.find{|r| r.name == :microposts}
        expect(relation.name).to eq :microposts
        expect(relation.array?).to eq true
        expect(relation.relation).to eq :has_many
        expect(relation.options).to eq @options

        relation = UserSerializer.relationships.find{|r| r.name == :unit}
        expect(relation.name).to eq :unit
        expect(relation.array?).to eq false
        expect(relation.relation).to eq :belongs_to
        expect(relation.options).to eq @options

        relation = UserSerializer.relationships.find{|r| r.name == :follower}
        expect(relation.name).to eq :follower
        expect(relation.array?).to eq false
        expect(relation.relation).to eq :has_one
        expect(relation.options).to eq @options
      end
    end
  end
end
