require 'spec_helper'

RSpec.describe SimpleAMS::DSL, 'name_value_hash' do
  %i[generic link meta form].map(&:to_s).each do |element|
    element.send(:extend, Module.new do
      def plural
        "#{self}s"
      end
    end)

    describe "(#{element.plural})" do
      context "with no #{element.plural}" do
        it 'returns an empty array' do
          expect(UserSerializer.send(element.plural)).to eq []
        end
      end

      context "with one #{element}" do
        before do
          @element = Elements.send(element)
          UserSerializer.send(element, *@element.as_input)
        end

        it "holds the specified #{element}" do
          expect(UserSerializer.send(element.plural).count).to eq 1
          expect(UserSerializer.send(element.plural).first).to eq @element.as_input
        end
      end

      context "with lambda #{element}" do
        before do
          @element = Elements.send(element)
          UserSerializer.send(element, *@element.as_lambda_input)
        end

        it 'holds the specified generic' do
          expect(UserSerializer.send(element.plural).count).to eq 1
          expect(UserSerializer.send(element.plural).first[1].is_a?(Proc)).to eq true
          expect(UserSerializer.send(element.plural).first[1].call).to eq @element.as_input[1..-1]
        end
      end

      context "with multiple #{element.plural}" do
        before do
          @elements = rand(2..11).times.map { Elements.send(element) }
          @elements.each do |t|
            UserSerializer.send(element, *t.as_input)
          end
        end

        it "holds the specified #{element.plural}" do
          expect(UserSerializer.send(element.plural).count).to eq @elements.count
          UserSerializer.send(element.plural).each_with_index do |t, index|
            expect(t).to eq @elements[index].as_input
            # just in case
            expect(t).to eq [@elements[index].name, @elements[index].value, @elements[index].options]
          end
        end
      end

      context "with multiple #{element.plural} at once" do
        before do
          @elements = rand(2..11).times.map { Elements.send(element) }.uniq(&:name)
          UserSerializer.send(element.plural, @elements.each_with_object({}) do |el, memo|
            memo[el.name] = el.as_input[1..-1]
          end)
        end

        it "holds the specified #{element.plural}" do
          expect(UserSerializer.send(element.plural).count).to eq @elements.count
          UserSerializer.send(element.plural).each_with_index do |t, index|
            expect(t).to eq @elements[index].as_input
            # just in case
            expect(t).to eq [@elements[index].name, @elements[index].value, @elements[index].options]
          end
        end
      end
    end
  end
end
