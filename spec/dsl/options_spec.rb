require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'options' do
  context "with no options" do
    it "returns the default" do
      expect(UserSerializer.options).to eq (
        {
          adapter: [SimpleAMS::Adapters::DEFAULT, {}],
          primary_id: [:id, {}],
          type: [:user, {}],
          fields: [],
          relationships: [],
          includes: [],
          links: [],
          metas: [],
        }
      )
    end
  end

  context "with multiple options" do
    before do
      @adapter = Elements.adapter
      UserSerializer.adapter(*@adapter.as_input)
      @primary_id = Elements.primary_id
      UserSerializer.primary_id(*@primary_id.as_input)
      @type = Elements.type
      UserSerializer.type(*@type.as_input)
      @attrs = Helpers::Options.array
      UserSerializer.attributes(*@attrs)
      @links = (rand(10) + 2).times.map{ Elements.link }
      @links.each{|link|
        UserSerializer.link(*link.as_input)
      }
      @meta = Elements.meta
      UserSerializer.meta(*@meta.as_input)
    end

    it "holds the specified options" do
      expect(UserSerializer.options).to eq (
        {
          adapter: @adapter.as_input,
          primary_id: @primary_id.as_input,
          type: @type.as_input,
          fields: @attrs,
          relationships: [],
          includes: [],
          links: @links.map(&:as_input),
          metas: [@meta.as_input],
        }
      )
    end
  end
end

