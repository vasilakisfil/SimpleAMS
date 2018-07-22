require "spec_helper"

RSpec.describe SimpleAMS::Options, 'type' do
  context "with no type is specified" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap{|h| h.delete(:type)}
      })
    end

    it "defaults to class name" do
      expect(@options.type.name).to eq User.to_s.downcase.to_sym
      expect(@options.name).to eq @options.type.name
    end

    it "updates name correctly" do
      expect(@options.name).to eq @options.type.name
    end
  end

  context "with no injected type" do
    before do
      @type = Elements.type
      UserSerializer.type(*@type.as_input)

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap{|h| h.delete(:type)}
      })
    end

    it "returns the type specified" do
      expect(@options.type.name).to eq @type.name
      expect(@options.type.options).to eq @type.options
    end

    it "updates name correctly" do
      expect(@options.name).to eq @options.type.name
    end
  end

  context "with injected type" do
    before do
      #TODO: add as_options method
      type = Elements.type
      UserSerializer.type(*type.as_input)

      @type = Elements.type
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          type: @type.as_input
        })
      })
    end

    it "returns the injected type specified" do
      expect(@options.type.name).to eq @type.value
      expect(@options.type.options).to eq(@type.options)
    end

    it "updates name correctly" do
      expect(@options.name).to eq @options.type.name
    end
  end
end
