require "spec_helper"

RSpec.describe SimpleAMS::Document, 'value_hash' do
  [:type, :primary_id, :adapter].map(&:to_s).each do |element|
    element.send(:extend, Module.new{
      def type?
        self.to_sym == :type
      end

      def primary_id?
        self.to_sym == :primary_id
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
          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
              }, without: [element.to_sym])
            })
          )
        end

        it "defaults to class name" do
          expect(@document.send(element).name).to eq element.default_name
        end

        if element.type?
          it "updates name correctly" do
            expect(@document.name).to eq @document.send(element).name
          end
        end

        if element.primary_id?
          it "value defaults to resource id" do
            expect(@document.send(element).value).to eq @document.resource.id
          end
        end
      end

      context "with no injected #{element}" do
        before do
          @element = Elements.send(element, value: :an_element, options: {foo: :bar})
          UserSerializer.send(element, *@element.as_input)

          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
              }, without: [element.to_sym])
            })
          )
        end

        it "returns the #{element} specified" do
          expect(@document.send(element).name).to eq :an_element
          expect(@document.send(element).options).to(
            eq({foo: :bar}.merge(element.default_options))
          )
        end

        if element.type?
          it "updates name correctly" do
            expect(@document.name).to eq @document.send(element).name
          end
        end
      end

      context "with injected #{element}" do
        before do
          if element.primary_id?
            UserSerializer.with_overrides({
              an_element: 'an_element_value',
              another_element: 'another_element_value'
            })
          end

          #TODO: add as_options method
          _element = Elements.send(element, value: :an_element, options: {foo: :bar})
          UserSerializer.send(element, *_element.as_input)

          @element = Elements.send(element, value: :another_element, options: {bar: :foo})
          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
                element.to_sym => @element.as_input
              })
            })
          )
        end

        if element.primary_id?
          after do
            UserSerializer.send(:remove_method, :an_element)
            UserSerializer.send(:remove_method, :another_element)
          end
        end

        it "returns the injected #{element} specified" do
          expect(@document.send(element).name).to eq @element.value
          expect(@document.send(element).options).to eq(@element.options)
        end

        if element.type?
          it "updates name correctly" do
            expect(@document.name).to eq @document.send(element).name
          end
        end

        if element.primary_id?
          it "value resource's value" do
            expect(@document.send(element).value).to eq 'another_element_value'
          end
        end
      end
    end
  end
end
