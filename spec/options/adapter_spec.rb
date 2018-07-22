require "spec_helper"

RSpec.describe SimpleAMS::Options, 'adapter' do
  context "with no adapter is specified" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
        }).tap{|h| h.delete(:adapter)}
      })
    end

    it "returns the default adapter" do
      expect(@options.adapter.name).to eq SimpleAMS::Adapters::AMS
    end
  end

  context "with no injected adapter" do
    before do
      @adapter = Elements.adapter
      UserSerializer.adapter(*@adapter.as_input)

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
        }).tap{|h| h.delete(:adapter)}
      })
    end

    it "returns the adapter specified" do
      expect(@options.adapter.name).to eq @adapter.name
      expect(@options.adapter.options).to eq @adapter.options
    end
  end

  context "with injected adapter" do
    before do
      #TODO: add as_options method
      adapter = Elements.adapter(value: OpenStruct)
      UserSerializer.adapter(*adapter.as_input)

      @another_adapter = Elements.adapter

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
          adapter: @another_adapter.as_input
        })
      })
    end

    it "returns the injected adapter specified" do
      expect(@options.adapter.name).to eq @another_adapter.name
      expect(@options.adapter.options).to eq @another_adapter.options
    end
  end
end

