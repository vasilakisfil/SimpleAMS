require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Options, 'primary_id' do
  context "with no primary_id in general" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap{|h| h.delete(:primary_id)}
      })
    end

    it "returns empty metas array" do
      expect(@options.primary_id.value).to eq :id
    end
  end

  context "with no injected primary_id" do
    before do
      @primary_id = Elements.primary_id
      UserSerializer.primary_id(*@primary_id.as_input)
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap{|h| h.delete(:primary_id)}
      })
    end

    it "returns the allowed ones" do
      expect(@options.primary_id.value).to eq @primary_id.value
      expect(@options.primary_id.options).to eq @primary_id.options
    end
  end
  context "with injected primary_id" do
    before do
      UserSerializer.primary_id(*Elements.primary_id.as_input)
      @primary_id = Elements.primary_id

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          primary_id: @primary_id.as_input
        })
      })
    end

    it "returns the injected primary_id" do
      expect(@options.primary_id.value).to eq @primary_id.value
      expect(@options.primary_id.options).to eq @primary_id.options
    end
  end
end
