require "spec_helper"

RSpec.describe SimpleAMS::Options, 'value_hash' do
  [:type, :primary_id, :adapter].map(&:to_s).each do |element|
    element.send(:extend, Module.new{
      def type?
        self.to_sym == :type
      end

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
      context "with no #{element} is specified" do
        before do
          @options = SimpleAMS::Options.new(User.new, {
            injected_options: Helpers.random_options(with:{
              serializer: UserSerializer,
            }).tap{|h| h.delete(element.to_sym)}
          })
        end

        it "defaults to class name" do
          expect(@options.send(element).name).to eq element.default_name
        end

        if element.type?
          it "updates name correctly" do
            expect(@options.name).to eq @options.send(element).name
          end
        end
      end

      context "with no injected #{element}" do
        before do
          @element = Elements.send(element)
          UserSerializer.send(element, *@element.as_input)

          @options = SimpleAMS::Options.new(User.new, {
            injected_options: Helpers.random_options(with:{
              serializer: UserSerializer,
            }).tap{|h| h.delete(element.to_sym)}
          })
        end

        it "returns the #{element} specified" do
          expect(@options.send(element).name).to eq @element.name
          expect(@options.send(element).options).to(
            eq @element.options.merge(element.default_options)
          )
        end

        if element.type?
          it "updates name correctly" do
            expect(@options.name).to eq @options.send(element).name
          end
        end
      end

      context "with injected #{element}" do
        before do
          #TODO: add as_options method
          allowed_element = Elements.send(element)
          UserSerializer.send(element, *allowed_element.as_input)

          @element = Elements.send(element)
          @options = SimpleAMS::Options.new(User.new, {
            injected_options: Helpers.random_options(with:{
              serializer: UserSerializer,
              element.to_sym => @element.as_input
            })
          })
        end

        it "returns the injected #{element} specified" do
          expect(@options.send(element).name).to eq @element.value
          expect(@options.send(element).options).to eq(@element.options)
        end

        if element.type?
          it "updates name correctly" do
            expect(@options.name).to eq @options.send(element).name
          end
        end
      end
    end
  end
end
