require "spec_helper"

RSpec.describe SimpleAMS::DSL do
  context "attributes" do
    before do
      @attrs = Helpers::Options.array
      User.attributes(*@attrs)
    end

    it "holds the specified options" do
      expect(User.attributes).to eq @attrs
      expect(User.relationships).to eq []
    end
  end
end
