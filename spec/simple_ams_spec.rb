require 'spec_helper'

RSpec.describe SimpleAMS do
  it 'has a version number' do
    expect(SimpleAMS::VERSION).not_to be nil
  end

  it 'raises error when using a non SimpleAMS class' do
    expect do
      SimpleAMS::Renderer.new(
        User.new,
        Helpers.random_options(with: {
          serializer: OpenStruct
        }).tap do |h|
          h.delete(:name)
        end
      )
    end.to raise_error(/does not respond to SimpleAMS methods/)
  end
end
