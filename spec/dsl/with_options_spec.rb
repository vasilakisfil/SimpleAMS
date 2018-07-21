require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'options' do
  context "with no with_options returns the default options" do
    it "returns the default" do
      expect(UserSerializer.options).to eq (
        {
          adapter: [SimpleAMS::Adapters::DEFAULT, {}],
          primary_id: [:id, {}],
          type: [:user, {}],
          fields: [],
          relations: [],
          includes: [],
          links: [],
          metas: [],
        }
      )
    end
  end

  context "with random with_options" do
    before do
      @random_options = Helpers.random_options
      UserSerializer.with_options(@random_options)
    end

    it "holds the specified options" do
      @random_options.each do |key, value|
        next unless UserSerializer.respond_to?(key)

        case key
        when :type, :primary_id
          expect(UserSerializer.options.send(:[], key)).to eq([value, {}])
        when :links, :metas
          expect(UserSerializer.options.send(:[], key)).to eq(value.map{|k, v| [k, v].flatten(1)})
        else
          expect(UserSerializer.options.send(:[], key)).to eq(value)
        end
      end
    end
  end

  context "with random with_options but overriden by DSL" do
    before do
      @random_options = Helpers.random_options
      UserSerializer.with_options(@random_options)

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

    it "holds the specified adapter options" do
      expect(UserSerializer.options[:adapter]).to eq(@adapter.as_input)
      expect(UserSerializer.options[:primary_id]).to eq(@primary_id.as_input)
      expect(UserSerializer.options[:type]).to eq(@type.as_input)
      expect(Helpers.recursive_sort(UserSerializer.options[:fields])).to(
        eq(Helpers.recursive_sort([@attrs, @random_options[:fields]].flatten(1)))
      )
      expect(UserSerializer.options[:links].sort).to eq([UserSerializer.options[:links], @links.map(&:as_input)].flatten(1).uniq.sort)
    end
  end
end


