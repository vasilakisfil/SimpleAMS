require "spec_helper"

RSpec.describe SimpleAMS::DSL do
  describe "links" do
    context "with one link" do
      before do
        @link = Elements.link
        User.link(*@link.as_input)
      end

      it "holds the specified options" do
        expect(User.links.count).to eq 1
        expect(User.links.first.keys.first).to eq @link.name
        expect(User.links.first.values.first.first).to eq @link.value
        expect(User.links.first.values.first.last).to eq @link.options
      end
    end

    context "with multiple links" do
      before do
        @links = (rand(10) + 2).times.map{ Elements.link }
        @links.each{|link|
          User.link(*link.as_input)
        }
      end

      it "holds the specified options" do
        expect(User.links.count).to eq @links.count
        User.links.each_with_index do |link, index|
          expect(link.keys.first).to eq @links[index].name
          expect(link.values.first.first).to eq @links[index].value
          expect(link.values.first.last).to eq @links[index].options
        end
      end
    end
  end
end
