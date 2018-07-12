require "spec_helper"

#relation with #type is tested in type_spec.rb tests
RSpec.describe SimpleAMS::Document, 'name' do
  context "with no name specified // no name injected" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
          }).tap{|h|
            h.delete(:name)
          }
        )
      )
    end

    it "defaults to type" do
      expect(@document.name).to eq @document.type.name
    end
  end

  context "with injected name" do
    before do
      @name = Helpers::Options.single

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
            name: @name
          })
        )
      )
    end

    it "returns the injected name specified" do
      expect(@document.name).to eq @name
    end

    it "has different type from name" do
      expect(@document.type.name).not_to eq @name
    end
  end
end
