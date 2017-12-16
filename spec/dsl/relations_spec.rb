require "spec_helper"

RSpec.describe SimpleAMS::DSL do
  #TODO: Add random options generator
  describe "relations" do
    describe "has_many" do
      context "plain" do
        before do
          User.has_many(:microposts)
        end

        it "holds the specified options" do
          expect(User.attributes).to eq []
          expect(User.relationships.count).to eq 1
          expect(User.relationships.first.name).to eq :microposts
          expect(User.relationships.first.array?).to eq true
          expect(User.relationships.first.relation).to eq :has_many
        end
      end

      context "with options" do
        before do
          @options = Helpers.random_options
          User.has_many(:microposts, @options)
        end

        it "holds the specified options" do
          expect(User.attributes).to eq []
          expect(User.relationships.count).to eq 1
          expect(User.relationships.first.name).to eq :microposts
          expect(User.relationships.first.array?).to eq true
          expect(User.relationships.first.relation).to eq :has_many
          expect(User.relationships.first.options).to eq @options
        end
      end
    end

    describe "has_one" do
      context "plain" do
        before do
          User.has_one(:follower)
        end

        it "holds the specified options" do
          expect(User.attributes).to eq []
          expect(User.relationships.count).to eq 1
          expect(User.relationships.first.name).to eq :follower
          expect(User.relationships.first.array?).to eq false
          expect(User.relationships.first.relation).to eq :has_one
        end
      end

      context "with options" do
        before do
          @options = Helpers.random_options
          User.has_one(:follower, @options)
        end

        it "holds the specified options" do
          expect(User.attributes).to eq []
          expect(User.relationships.count).to eq 1
          expect(User.relationships.first.name).to eq :follower
          expect(User.relationships.first.array?).to eq false
          expect(User.relationships.first.relation).to eq :has_one
          expect(User.relationships.first.options).to eq @options
        end
      end
    end

    describe "belongs_to" do
      context "plain" do
        before do
          User.belongs_to(:unit)
        end

        it "holds the specified options" do
          expect(User.attributes).to eq []
          expect(User.relationships.count).to eq 1
          expect(User.relationships.first.name).to eq :unit
          expect(User.relationships.first.array?).to eq false
          expect(User.relationships.first.relation).to eq :belongs_to
        end
      end

      context "with options" do
        before do
          @options = Helpers.random_options
          User.belongs_to(:unit, @options)
        end

        it "holds the specified options" do
          expect(User.attributes).to eq []
          expect(User.relationships.count).to eq 1
          expect(User.relationships.first.name).to eq :unit
          expect(User.relationships.first.array?).to eq false
          expect(User.relationships.first.relation).to eq :belongs_to
          expect(User.relationships.first.options).to eq @options
        end
      end
    end

    describe "combined" do
      context "plain" do
        before do
          @options = Helpers.random_options

          User.has_many(:microposts, @options)
          User.belongs_to(:unit, @options)
          User.has_one(:follower, @options)
        end

        it "holds the specified options" do
          expect(User.attributes).to eq []
          expect(User.relationships.count).to eq 3

          relation = User.relationships.find{|r| r.name == :microposts}
          expect(relation.name).to eq :microposts
          expect(relation.array?).to eq true
          expect(relation.relation).to eq :has_many
          expect(relation.options).to eq @options

          relation = User.relationships.find{|r| r.name == :unit}
          expect(relation.name).to eq :unit
          expect(relation.array?).to eq false
          expect(relation.relation).to eq :belongs_to
          expect(relation.options).to eq @options

          relation = User.relationships.find{|r| r.name == :follower}
          expect(relation.name).to eq :follower
          expect(relation.array?).to eq false
          expect(relation.relation).to eq :has_one
          expect(relation.options).to eq @options
        end
      end
    end
  end
end
