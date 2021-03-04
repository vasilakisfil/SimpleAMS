require 'spec_helper'

# relation with #type is tested in type_spec.rb tests
RSpec.describe SimpleAMS::Options, 'name' do
  context 'with no name specified // no name injected' do
    before do
      @options = SimpleAMS::Options.new(
        User.new,
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer
        }).tap do |h|
          h.delete(:name)
        end
      )
    end

    it 'defaults to type' do
      expect(@options.name).to eq @options.type.name
    end
  end

  context 'with injected name' do
    before do
      @name = Helpers::Options.single

      @options = SimpleAMS::Options.new(
        User.new,
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
          name: @name
        })
      )
    end

    it 'returns the injected name specified' do
      expect(@options.name).to eq @name
    end

    it 'has different type from name' do
      expect(@options.type.name).not_to eq @name
    end
  end
end
