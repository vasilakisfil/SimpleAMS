require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'options' do
  context "with no options" do
    it "returns the default" do
      expect(UserSerializer.options).to eq (
        {
          adapter: [SimpleAMS::Adapters::AMS, {}],
          primary_id: [:id, {}],
          type: [:user, {}],
          fields: [],
          relations: [],
          includes: [],
          links: [],
          metas: [],
          forms: [],
          generics: [],
          collection: UserSerializer::Collection_
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
      @form = Elements.form
      UserSerializer.form(*@form.as_input)
      @generic = Elements.generic
      UserSerializer.generic(*@generic.as_input)
    end

    it "holds the specified options" do
      expect(UserSerializer.options).to eq (
        {
          adapter: @adapter.as_input,
          primary_id: @primary_id.as_input,
          type: @type.as_input(_explicit: true ),
          fields: @attrs.uniq,
          relations: [],
          includes: [],
          links: @links.map(&:as_input),
          metas: [@meta.as_input],
          forms: [@form.as_input],
          generics: [@generic.as_input],
          collection: UserSerializer::Collection_
        }
      )
    end
  end

  #TODO: Move that to general tests?
  it "responds to simple_ams? method" do
    expect(UserSerializer).to respond_to(:simple_ams?)
    expect(UserSerializer.simple_ams?).to eq true
  end
end

