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
        expect(UserSerializer.relationships.first).to eq [:microposts, :has_many, {}]
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
        expect(UserSerializer.relationships.first).to eq [:microposts, :has_many, {options: @options}]
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
        expect(UserSerializer.relationships.first).to eq [:follower, :has_one, {}]
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
        expect(UserSerializer.relationships.first).to eq [:follower, :has_one, {options: @options}]
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
        expect(UserSerializer.relationships.first).to eq [:unit, :belongs_to, {}]
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
        expect(UserSerializer.relationships.first).to eq [:unit, :belongs_to, {options: @options}]
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

        relation = UserSerializer.relationships.find{|r| r.first == :microposts}
        expect(relation).to eq [:microposts, :has_many, {options: @options}]

        relation = UserSerializer.relationships.find{|r| r.first == :unit}
        expect(relation).to eq [:unit, :belongs_to, {options: @options}]

        relation = UserSerializer.relationships.find{|r| r.first == :follower}
        expect(relation).to eq [:follower, :has_one, {options: @options}]
      end
    end
  end
end
