require "spec_helper"

RSpec.describe SimpleAMS::DSL do
  describe "by incuding plain DSL" do
    it "creates the default options" do
      expect(User.attributes).to eq []
      expect(User.relationships).to eq []
    end
  end
end
