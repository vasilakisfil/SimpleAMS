require 'spec_helper'

RSpec.describe SimpleAMS::Options, 'collection' do
  context 'with no collection properties are injected' do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer
        }).tap do |h|
                            h.delete(:collection)
                          end
      })
    end

    it 'defaults to nil' do
      expect(@options.collection_options.fields).to eq []
    end
  end

  context 'with injected options only' do
    before do
      @injected_options = Helpers.random_options(with: {
        serializer: UserSerializer
      })

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: @injected_options
      })
    end

    it 'returns the injected name specified' do
      expect(@options.collection_options.links).to eq []
      expect(@options.collection_options.metas).to eq []
    end
  end

  context 'with injected options that override allowed_options' do
    before do
      Helpers.define_singleton_for('RandomOptions', {
        allowed_links: Elements.links,
        allowed_metas: Elements.metas
      })
      UserSerializer.collection do
        Helpers::RandomOptions.allowed_links.each do |link|
          link(*link.as_input)
        end

        Helpers::RandomOptions.allowed_metas.each do |meta|
          meta(*meta.as_input)
        end
      end

      @injected_links = Elements.as_options_for(
        Helpers.pick(Helpers::RandomOptions.allowed_links)
      )
      @injected_metas = Elements.as_options_for(
        Helpers.pick(Helpers::RandomOptions.allowed_metas)
      )

      injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        collection: {
          links: @injected_links,
          metas: @injected_metas
        }
      })

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: injected_options
      })
    end

    it 'holds the uniq union of injected and allowed links' do
      _allowed_links = Helpers::RandomOptions.allowed_links

      links_got = @options.collection_options.links
      _injected_links = Elements.as_elements_for(
        @injected_links, klass: Elements::Link
      )

      links_expected = (_injected_links.map(&:name) & _allowed_links.map(&:name)).map do |name|
        _injected_links.find { |l| l.name == name }
      end

      expect(links_got.map(&:name)).to eq(links_expected.map(&:name))
      expect(links_got.map(&:value)).to eq(links_expected.map(&:value))
      expect(links_got.map(&:options)).to eq(links_expected.map(&:options))
    end
  end

  context 'when collection is not an array' do
    let(:collection) do
      Class.new do
        def initialize(arr)
          @arr = arr
        end

        def to_a
          @arr
        end

        def [](index)
          @arr[index]
        end

        def first
          @arr.first
        end

        def last
          @arr.last
        end
      end.new([User.new])
    end

    let(:options) { SimpleAMS::Options.new(collection) }

    it 'infers serialier class correctly' do
      expect(options.serializer_class).to eq UserSerializer
    end
  end
end
