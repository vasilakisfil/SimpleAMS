require "spec_helper"

RSpec.describe SimpleAMS::Document, 'type' do
  context "with no type is specified" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
          }).tap{|h| h.delete(:type)}
        })
      )
    end

    it "defaults to class name" do
      expect(@document.type.name).to eq User.to_s.downcase.to_sym
      expect(@document.name).to eq @document.type.name
    end

    it "updates name correctly" do
      expect(@document.name).to eq @document.type.name
    end
  end

  context "with no injected type" do
    before do
      @type = Elements.type(value: :a_type, options: {foo: :bar})
      UserSerializer.type(*@type.as_input)

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
          }).tap{|h| h.delete(:type)}
        })
      )
    end

    it "returns the type specified" do
      expect(@document.type.name).to eq :a_type
      expect(@document.type.options).to eq({foo: :bar, _explicit: true})
    end

    it "updates name correctly" do
      expect(@document.name).to eq @document.type.name
    end
  end

  context "with injected type" do
    before do
      #TODO: add as_options method
      type = Elements.type(value: :a_type, options: {foo: :bar})
      UserSerializer.type(*type.as_input)

      @type = Elements.type(value: :another_type, options: {bar: :foo})
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            type: @type.as_input
          })
        })
      )
    end

    it "returns the injected type specified" do
      expect(@document.type.name).to eq @type.value
      expect(@document.type.options).to eq(@type.options)
    end

    it "updates name correctly" do
      expect(@document.name).to eq @document.type.name
    end
  end
end
