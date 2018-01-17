require "spec_helper"

RSpec.describe SimpleAMS::DSL do
  describe "by incuding plain DSL" do
    it "creates the default options" do
      expect(UserSerializer.attributes).to eq []
      expect(UserSerializer.relationships).to eq []
    end
  end
end
