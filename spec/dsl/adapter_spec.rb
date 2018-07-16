require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'adapter' do
  context "without specifying adapter" do
    before do
    end

    it "returns the default adapter (AMS)" do
      expect(UserSerializer.adapter).to eq [SimpleAMS::Adapters::AMS, {}]
    end
  end

  context "with plain adapter name" do
    before do
      @adapter_options = Elements.adapter(value: OpenStruct, options: {})
      UserSerializer.adapter(*@adapter_options.as_input)
    end

    it "holds the adapter name" do
      expect(UserSerializer.adapter).to eq @adapter_options.as_input
    end
  end

  context "with options for the adapter" do
    before do
      @adapter_options = Elements.adapter(
        value: OpenStruct, options: Helpers::Options.hash
      )
      UserSerializer.adapter(*@adapter_options.as_input)
    end

    it "holds the specified options" do
      expect(UserSerializer.adapter).to eq @adapter_options.as_input
      #just in case
      expect(UserSerializer.adapter).to eq [@adapter_options.value, @adapter_options.options]
    end
  end
end
