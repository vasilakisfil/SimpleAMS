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
      expect(UserSerializer.links.first).to eq @link.as_input
    end
  end

  context "with lambda link" do
    before do
      @link = Elements.link
      UserSerializer.link(*@link.as_lambda_input)
    end

    it "holds the specified link" do
      expect(UserSerializer.links.count).to eq 1
      expect(UserSerializer.links.first[1].is_a?(Proc)).to eq true
      expect(UserSerializer.links.first[1].call).to eq @link.as_input[1..-1]
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
        expect(link).to eq @links[index].as_input
        #just in case
        expect(link).to eq [@links[index].name, @links[index].value, options: @links[index].options]
      end
    end
  end
end
