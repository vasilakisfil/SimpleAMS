require "spec_helper"

RSpec.describe SimpleAMS::Options, 'as_hash' do
  context "with no options" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: {serializer: UserSerializer}
      })
    end

    it "returns the default" do
      expect(@options.as_hash).to eq (
        {
          adapter: [SimpleAMS::Adapters::DEFAULT, {}],
          primary_id: [:id, {}],
          type: [:user, {}],
          fields: [],
          serializer: UserSerializer,
          #relations: [],
          includes: [],
          links: [],
          metas: [],
          expose: {},
          _internal: {},
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
      @links = (rand(10) + 2).times.map{ Elements.link }.uniq{|l| l.name}
      @links.each{|link|
        UserSerializer.link(*link.as_input)
      }
      @meta = Elements.meta
      UserSerializer.meta(*@meta.as_input)

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: {serializer: UserSerializer}
      })
    end

    it "holds the specified options" do
      expect(@options.as_hash).to eq (
        {
          adapter: @adapter.as_input,
          primary_id: @primary_id.as_input,
          type: @type.as_input,
          fields: @attrs.uniq,
          serializer: UserSerializer,
          #relations: [],
          includes: [],
          links: @links.map(&:as_input),
          metas: [@meta.as_input],
          expose: {},
          _internal: {},
        }
      )
    end
  end

  context "it includes relations in hash as well" do
    pending('Needs implementation')
  end
end

