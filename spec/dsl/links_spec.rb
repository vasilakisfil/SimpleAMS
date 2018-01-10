require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'links' do
  context "with no links" do
    it "returns an empty array" do
      expect(UserSerializer.links).to eq []
    end
  end

  context "with one link" do
    before do
      @link = Elements.link
      UserSerializer.link(*@link.as_input)
    end

    it "holds the specified link" do
      expect(UserSerializer.links.count).to eq 1
      expect(UserSerializer.links.first.name).to eq @link.name.to_sym
      expect(UserSerializer.links.first.value).to eq @link.value
      expect(UserSerializer.links.first.options).to eq @link.options
    end
  end

  context "with multiple links" do
    before do
      @links = (rand(10) + 2).times.map{ Elements.link }
      @links.each{|link|
        UserSerializer.link(*link.as_input)
      }
    end

    it "holds the specified links" do
      expect(UserSerializer.links.count).to eq @links.count
      UserSerializer.links.each_with_index do |link, index|
        expect(link.name).to eq @links[index].name.to_sym
        expect(link.value).to eq @links[index].value
        expect(link.options).to eq @links[index].options
      end
    end
  end
end
