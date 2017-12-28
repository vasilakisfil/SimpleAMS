require "spec_helper"

RSpec.describe SimpleAMS::DSL do
  describe "adapter" do
    context "without specifying adapter" do
      before do
      end

      it "holds the specified options" do
        expect(User.adapter.name).to eq :ams
      end
    end

    context "plain" do
      before do
        @adapter_options = Elements.adapter(options: {})
        User.adapter(*@adapter_options.as_input)
      end

      it "holds the specified options" do
        expect(User.adapter.name).to eq @adapter_options.name.to_sym
      end
    end

    context "with options" do
      before do
        @adapter_options = Elements.adapter
        User.adapter(*@adapter_options.as_input)
      end

      it "holds the specified options" do
        expect(User.adapter.name).to eq @adapter_options.name.to_sym
        expect(User.adapter.options).to eq @adapter_options.options
      end
    end
  end
end
