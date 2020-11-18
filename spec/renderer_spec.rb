require "spec_helper"

RSpec.describe SimpleAMS::Renderer, 'name' do
  context "with no name specified // no name injected" do
    before do
      @renderer = SimpleAMS::Renderer.new(
        User.new,
        Helpers.random_options(with: {
          serializer: UserSerializer,
        }).tap { |h|
          h.delete(:name)
        }
      )
    end

    it "defaults to type" do
      expect(@renderer.name).to eq @renderer.document.type.name
    end
  end

  context "with injected name" do
    before do
      @name = Helpers::Options.single

      @renderer = SimpleAMS::Renderer.new(
        User.new,
        Helpers.random_options(with: {
          serializer: UserSerializer,
          name: @name
        })
      )
    end

    it "returns the injected name specified" do
      expect(@renderer.name).to eq @name
    end

    it "has different type from name" do
      expect(@renderer.document.type.name).not_to eq @name
    end
  end
end
