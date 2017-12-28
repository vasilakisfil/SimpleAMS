require "spec_helper"

RSpec.describe SimpleAMS::DSL do
  describe "primary_id" do
    context "when NOT specified" do
      it "holds the specified options" do
        expect(User.primary_id.value).to eq :id
      end
    end

    context "when specified" do
      before do
        @id = Helpers::Options.single
        User.primary_id(@id)
      end

      it "holds the specified options" do
        expect(User.primary_id.value).to eq @id
      end
    end
  end
end

