require "spec_helper"

RSpec.describe SimpleAMS::Options, 'adapter' do
  context "with no adapter is specified" do
    before do
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
        }).tap{|h| h.delete(:adapter)}
      )
    end

    it "returns the default adapter" do
      expect(@options.adapter.name).to eq SimpleAMS::Adapters::AMS
    end
  end

  context "with no injected adapter" do
    before do
      @adapter = Elements.adapter(value: Helpers::Adapter1, options: {foo: :bar})
      UserSerializer.adapter(*@adapter.as_input)

      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
        }).tap{|h| h.delete(:adapter)}
      )
    end

    it "returns the adapter specified" do
      expect(@options.adapter.name).to eq Helpers::Adapter1
      expect(@options.adapter.options).to eq({foo: :bar})
    end
  end

  context "with injected adapter" do
    before do
      #TODO: add as_options method
      @adapter = Elements.adapter(value: Helpers::Adapter1, options: {foo: :bar})
      UserSerializer.adapter(*@adapter.as_input)

      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
          adapter: [Helpers::Adapter2, options: {injected: true}]
        })
      )
    end

    it "returns the injected adapter specified" do
      expect(@options.adapter.name).to eq Helpers::Adapter2
      expect(@options.adapter.options).to eq({injected: true})
    end
  end
end

