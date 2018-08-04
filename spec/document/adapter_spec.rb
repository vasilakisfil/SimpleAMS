require "spec_helper"

RSpec.describe SimpleAMS::Document, 'fields' do
  context "with no adapter set" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }, without: [:adapter])
        })
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.adapter.value).to eq SimpleAMS::Adapters::AMS
      end
    end
  end

  context "with custom injected adapter and adapter options set" do
    before do
      adapter = Elements.adapter(value: OpenStruct)
      UserSerializer.adapter(*adapter.as_input)

      @another_adapter = Elements.adapter

      options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
          adapter: @another_adapter.as_input
        })
      })
      @document = SimpleAMS::Document.new(options)
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.adapter.value).to eq @another_adapter.name
        expect(@document.adapter.options).to eq @another_adapter.options
      end
    end
  end
end
