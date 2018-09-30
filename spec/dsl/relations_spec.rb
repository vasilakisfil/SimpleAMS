require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'relations' do
  context "with no relations" do
    it "returns an empty array" do
      expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relations).to eq []
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
        expect(UserSerializer.relations.count).to eq 1
        expect(UserSerializer.relations.first).to eq(
          [:has_many, :microposts, {}, UserSerializer::EmbeddedMicropostsOptions_]
        )
      end
    end

    context "with options" do
      before do
        @options = Helpers.random_options
        UserSerializer.has_many(:microposts, @options)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relations.count).to eq 1
        expect(UserSerializer.relations.first).to eq(
          [:has_many, :microposts, @options, UserSerializer::EmbeddedMicropostsOptions_]
        )
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
        expect(UserSerializer.relations.count).to eq 1
        expect(UserSerializer.relations.first).to eq(
          [:has_one, :follower, {}, UserSerializer::EmbeddedFollowerOptions_]
        )
      end
    end

    context "with options" do
      before do
        @options = Helpers.random_options
        UserSerializer.has_one(:follower, @options)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relations.count).to eq 1
        expect(UserSerializer.relations.first).to eq(
          [:has_one, :follower, @options, UserSerializer::EmbeddedFollowerOptions_]
        )
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
        expect(UserSerializer.relations.count).to eq 1
        expect(UserSerializer.relations.first).to eq(
          [:belongs_to, :unit, {}, UserSerializer::EmbeddedUnitOptions_]
        )
      end
    end

    context "with options" do
      before do
        @options = Helpers.random_options
        UserSerializer.belongs_to(:unit, @options)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relations.count).to eq 1
        expect(UserSerializer.relations.first).to eq(
          [:belongs_to, :unit, @options, UserSerializer::EmbeddedUnitOptions_]
        )
      end
    end
  end

  describe "combined" do
    context "plain" do
      before do
        @options = Helpers.random_options

        UserSerializer.has_many(:microposts, @options)
        UserSerializer.belongs_to(:unit, @options)
        UserSerializer.has_one(:follower, @options)
      end

      it "holds the specified options" do
        expect(UserSerializer.attributes).to eq []
        expect(UserSerializer.relations.count).to eq 3

        relation = UserSerializer.relations.find{|r| r[1] == :microposts}
        expect(relation).to eq(
          [:has_many, :microposts, @options, UserSerializer::EmbeddedMicropostsOptions_]
        )

        relation = UserSerializer.relations.find{|r| r[1] == :unit}
        expect(relation).to eq(
          [:belongs_to, :unit, @options,  UserSerializer::EmbeddedUnitOptions_]
        )

        relation = UserSerializer.relations.find{|r| r[1] == :follower}
        expect(relation).to eq(
          [:has_one, :follower, @options, UserSerializer::EmbeddedFollowerOptions_]
        )
      end
    end
  end
end
