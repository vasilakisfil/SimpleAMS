require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'type' do
  context "when NOT specified" do
    it "holds the default type key (nil)" do
      expect(UserSerializer.type.value).to eq nil
    end
  end

  context "when specified" do
    context "without options" do
      before do
        @type = Helpers::Options.single
        UserSerializer.type(@type)
      end

      it "holds the selected type key" do
        expect(UserSerializer.type.value).to eq @type
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
        expect(UserSerializer.type.value).to eq @type.name
        expect(UserSerializer.type.options).to eq @type.options
      end
    end
  end
end
