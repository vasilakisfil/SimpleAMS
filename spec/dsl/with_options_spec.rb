require 'spec_helper'

RSpec.describe SimpleAMS::DSL, 'options' do
  context 'with no with_options returns the default options' do
    it 'returns the default' do
      expect(UserSerializer.options).to eq(
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

  context 'with random with_options' do
    before do
      # TODO: Figure out what's going on when collection is nil or {},
      # i.e. add tests for these cases
      @random_options = Helpers.random_options(without: [:collection])
      UserSerializer.with_options(@random_options)
    end

    it 'holds the specified options' do
      @random_options.each do |key, value|
        next unless UserSerializer.respond_to?(key)

        case key
        when :primary_id
          expect(UserSerializer.options.send(:[], key)).to eq([value, {}])
        when :type
          expect(UserSerializer.options.send(:[], key)).to eq([value, { _explicit: true }])
        when :links, :metas, :forms, :generics
          expect(UserSerializer.options.send(:[], key)).to eq(value.map { |k, v| [k, v].flatten(1) })
        when :collection
          expect(UserSerializer.options[:collection]).to(
            eq(UserSerializer::Collection_)
          )
          expect(UserSerializer.options[:collection].links).to(
            eq(value[:links].map { |k, v| [k, v].flatten(1) })
          )
        when :includes
          expect(UserSerializer.options.send(:[], key)).to eq([])
        else
          expect(UserSerializer.options.send(:[], key)).to eq(value)
        end
      end
    end
  end

  context 'with random with_options but overriden by DSL' do
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
      @links = rand(2..11).times.map { Elements.link }
      @links.each do |link|
        UserSerializer.link(*link.as_input)
      end
      @meta = Elements.meta
      UserSerializer.meta(*@meta.as_input)
    end

    it 'holds the specified adapter options' do
      expect(UserSerializer.options[:adapter]).to eq(@adapter.as_input)
      expect(UserSerializer.options[:primary_id]).to eq(@primary_id.as_input)
      expect(UserSerializer.options[:type]).to eq(@type.as_input(_explicit: true))
      expect(Helpers.recursive_sort(UserSerializer.options[:fields])).to(
        eq(Helpers.recursive_sort([@attrs, @random_options[:fields]].flatten(1)).uniq)
      )
      expect(UserSerializer.options[:links].sort).to(
        eq([UserSerializer.options[:links], @links.map(&:as_input)].flatten(1).uniq.sort)
      )
    end
  end

  context "with options that don't really exist" do
    before do
      # TODO: Figure out what's going on when collection is nil or {},
      # i.e. add tests for these cases
      @random_options = { foo: :bar }
      @spy_logger = spy('::Logger')
      SimpleAMS.configure do |config|
        config.logger = @spy_logger
      end
      UserSerializer.with_options(@random_options)
    end

    it 'holds the specified options' do
      expect(@spy_logger).to have_received(:info)
    end
  end
end
