require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'primary_id' do
  context "when NOT specified" do
    it "holds the default primary_id key (:id)" do
      expect(UserSerializer.primary_id).to eq [:id, {}]
    end
  end

  context "when specified" do
    context "without options" do
      before do
        @id = Helpers::Options.single
        UserSerializer.primary_id(@id)
      end

      it "holds the selected primary_id key" do
        expect(UserSerializer.primary_id).to eq [@id, {}]
      end
    end

    context "with options" do
      before do
        @primary_id = Elements.type(
          value: Helpers::Options.single, options: Helpers::Options.hash
        )
        UserSerializer.primary_id(*@primary_id.as_input)
      end

      it "holds the selected type key" do
        expect(UserSerializer.primary_id).to eq @primary_id.as_input
        #just in case
        expect(UserSerializer.primary_id).to eq [@primary_id.value, @primary_id.options]
      end
    end
  end
end
