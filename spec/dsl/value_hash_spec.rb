require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'value_hash' do
  [:type, :primary_id, :adapter].map(&:to_s).each do |element|
    element.send(:extend, Module.new{
      def default_name
        return :user if self.to_sym == :type
        return :id if self.to_sym == :primary_id
        return SimpleAMS::Adapters::AMS if self.to_sym == :adapter
      end

      def default_options
        return {_explicit: true} if self.to_sym == :type
        return {}
      end
    })

    describe "(#{element})" do
      context "when NOT specified" do
        it "holds the default #{element} key (nil)" do
          expect(UserSerializer.send(element)).to eq [element.default_name, {}]
        end
      end

      context "when specified" do
        context "without options" do
          before do
            @element = Elements.send(element, {
              value: Helpers::Options.single, options: Helpers::Options.hash
            })
            UserSerializer.send(element, @element)
          end

          it "holds the selected #{element} key" do
            expect(UserSerializer.send(element)).to(
              eq [@element, element.default_options]
            )
          end
        end

        context "with options" do
          before do
            @element = Elements.send(element, {
              value: Helpers::Options.single, options: Helpers::Options.hash
            })
            UserSerializer.send(element, *@element.as_input)
          end

          it "holds the selected #{element} key" do
            expect(UserSerializer.send(element)).to(
              eq @element.as_input(element.default_options)
            )
            expect(UserSerializer.send(element)).to(
              eq [@element.value, @element.options.merge(element.default_options)]
            )
          end
        end
      end
    end
  end
end
