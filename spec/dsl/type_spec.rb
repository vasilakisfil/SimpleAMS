require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'type' do
  context "when NOT specified" do
    it "holds the default type key (nil)" do
      expect(UserSerializer.type).to eq [:user, {}]
    end
  end

  context "when specified" do
    context "without options" do
      before do
        @type = Elements.type(
          value: Helpers::Options.single, options: Helpers::Options.hash
        )
        UserSerializer.type(@type)
      end

      it "holds the selected type key" do
        expect(UserSerializer.type).to eq [@type, {}]
      end
    end

    context "with options" do
      before do
        @type = Elements.type(
          value: Helpers::Options.single, options: Helpers::Options.hash
        )
        UserSerializer.type(*@type.as_input)
      end

      it "holds the selected type key" do
        expect(UserSerializer.type).to eq @type.as_input
        expect(UserSerializer.type).to eq [@type.value, @type.options]
      end
    end
  end
end
