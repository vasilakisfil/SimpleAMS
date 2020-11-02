require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'array values' do
  [:attribute].map(&:to_s).each do |element|
    element.send(:extend, Module.new {
      def plural
        "#{self.to_s}s"
      end
    })

    describe "(#{element.plural})" do
      context "with no relations" do
        it "returns an empty array" do
          expect(UserSerializer.send(element.plural)).to eq []
        end
      end

      context "with #{element.plural} specified" do
        before do
          @attrs = Helpers::Options.array
          UserSerializer.send(element.plural, *@attrs)
        end

        it "holds the #{element.plural} specified" do
          expect(UserSerializer.send(element.plural)).to eq @attrs.uniq
        end
      end

      context "when resetting #{element.plural}" do
        before do
          @attrs = Helpers::Options.array
          UserSerializer.send(element.plural, *@attrs)
          class MinifiedUserSerializer < UserSerializer; end
        end

        it "it doesn't take into account pre-existing #{element.plural}" do
          expect(UserSerializer.send(element.plural)).to eq @attrs.uniq

          expect(MinifiedUserSerializer.send(element.plural)).to eq @attrs.uniq

          MinifiedUserSerializer.send("#{element.plural}=", [])
          expect(MinifiedUserSerializer.send(element.plural)).to eq []
        end
      end
    end
  end
end
