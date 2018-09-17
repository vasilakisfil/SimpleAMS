require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'attributes' do
  context "with no relations" do
    it "returns an empty array" do
      expect(UserSerializer.attributes).to eq []
    end
  end

  context "with attributes specified" do
    before do
      @attrs = Helpers::Options.array
      UserSerializer.attributes(*@attrs)
    end

    it "holds the attributes specified" do
      expect(UserSerializer.attributes).to eq @attrs.uniq
      expect(UserSerializer.relations).to eq []
    end
  end

  context "when resetting attributes" do
    before do
      @attrs = Helpers::Options.array
      UserSerializer.attributes(*@attrs)
      class MinifiedUserSerializer < UserSerializer; end
    end

    it "it doesn't take into account pre-existing attributes" do
      expect(UserSerializer.attributes).to eq @attrs.uniq
      expect(UserSerializer.relations).to eq []

      expect(MinifiedUserSerializer.attributes).to eq @attrs.uniq
      expect(MinifiedUserSerializer.relations).to eq []

      MinifiedUserSerializer.attributes= []
      expect(MinifiedUserSerializer.attributes).to eq []
    end
  end
end
