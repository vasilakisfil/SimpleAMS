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
      expect(UserSerializer.attributes).to eq @attrs
      expect(UserSerializer.relationships).to eq []
    end
  end
end
