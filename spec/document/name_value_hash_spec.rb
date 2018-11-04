require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Document, 'name_value_hash' do
  [:generic, :link, :meta, :form].map(&:to_s).each do |element|
    element.send(:extend, Module.new{
      def plural
        "#{self.to_s}s"
      end
    })

    describe "(#{element.plural})" do
      context "with no #{element.plural} in general" do
        before do
          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
              }).tap{|h| h.delete(element.to_sym)}
            })
          )
        end

        describe "members" do
          it "returns an empty array" do
            expect(@document.send(element.plural)).to eq({})
          end
        end

        describe "values" do
          it "returns an empty array" do
            expect(@document.send(element.plural)).to respond_to(:each)
            @document.send(element.plural).each do |field|
              fail('this should never happen as fields should be empty')
            end
          end
        end
      end

      context "with no injected #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          @allowed_elements.each do |el|
            UserSerializer.send(element, *el.as_input)
          end

          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer
              }).tap{|h| h.delete(element.plural.to_sym)}
            })
          )

          @uniq_allowed_elements = @allowed_elements.uniq{|el| el.name}
        end

        describe "members" do
          it "returns an empty array" do
            expect(@document.send(element.plural)).not_to eq({})
          end
        end

        it "returns the allowed ones" do
          expect(@document.send(element.plural).map(&:name)).to eq @uniq_allowed_elements.map(&:name)
          expect(@document.send(element.plural).map(&:value)).to eq @uniq_allowed_elements.map(&:value)
          expect(@document.send(element.plural).map(&:options)).to eq @uniq_allowed_elements.map(&:options)
        end
      end

      context "with empty injected #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          @allowed_elements.each do |el|
            UserSerializer.send(element, *el.as_input)
          end

          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
                element.plural.to_sym => []
              })
            })
          )
        end

        describe "members" do
          it "returns an empty array" do
            expect(@document.send(element.plural)).to(eq({}))
          end
        end

        describe "values" do
          it "returns an empty array" do
            expect(@document.send(element.plural)).to respond_to(:each)
            @document.send(element.plural).each do |field|
              fail('this should never happen as fields should be empty')
            end
          end
        end
      end

      context "with no allowed #{element.plural} but injected ones" do
        before do
          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
              })
            })
          )
        end

        describe "members" do
          it "returns an empty array" do
            expect(@document.send(element.plural)).to eq({})
          end
        end

        describe "values" do
          it "returns an empty array" do
            expect(@document.send(element.plural)).to respond_to(:each)
            @document.send(element.plural).each do |field|
              fail('this should never happen as fields should be empty')
            end
          end
        end
      end

      context "with various injected #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          @allowed_elements.each do |el|
            UserSerializer.send(element, *el.as_input)
          end
          @injected_elements = Elements.as_options_for(
            Helpers.pick(@allowed_elements)
          )

          injected_options = Helpers.random_options(with: {
            serializer: UserSerializer,
            element.plural.to_sym => @injected_elements
          })
          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, injected_options: injected_options)
          )
        end

        it "holds the uniq union of injected and allowed #{element.plural}" do
          elements_got = @document.send(element.plural)
          elements_expected = (Elements.as_elements_for(
            @injected_elements, klass: Object.const_get("Elements::#{element.capitalize}")
          ) + @allowed_elements).uniq{|q| q.name}.select{|l|
            @allowed_elements.map(&:name).include?(l.name) && @injected_elements.keys.include?(l.name)
          }

          expect(elements_got.map(&:name)).to eq(elements_expected.map(&:name))
          expect(elements_got.map(&:value)).to eq(elements_expected.map(&:value))
          expect(elements_got.map(&:options).count).to eq(elements_expected.map(&:options).count)
          expect(elements_got.map(&:options)).to eq(elements_expected.map(&:options))
        end
      end

      context "with repeated (allowed) #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          2.times{
            @allowed_elements.each do |el|
              UserSerializer.send(element, *el.as_input)
            end
          }
          @injected_elements = Elements.as_options_for(
            Helpers.pick(@allowed_elements)
          )

          injected_options = Helpers.random_options(with: {
            serializer: UserSerializer,
            element.plural.to_sym => @injected_elements
          })
          @document = SimpleAMS::Document.new(
            SimpleAMS::Options.new(User.new, injected_options: injected_options)
          )
        end

        it "holds the uniq union of injected and allowed #{element.plural}" do
          elements_got = @document.send(element.plural)
          _injected_elements = Elements.as_elements_for(
            @injected_elements, klass: Object.const_get("Elements::#{element.capitalize}")
          )

          elements_expected = (_injected_elements.map(&:name) & @allowed_elements.map(&:name)).map{|name|
            _injected_elements.find{|el| el.name == name}
          }

          expect(elements_got.map(&:name)).to eq(elements_expected.map(&:name))
          expect(elements_got.map(&:value)).to eq(elements_expected.map(&:value))
          expect(elements_got.map(&:options)).to eq(elements_expected.map(&:options))
        end
      end

      context "accessing a #{element} through Document::#{element.capitalize} class" do
        before do
          @allowed_elements = Elements.send(element.plural)
          @allowed_elements.each do |el|
            UserSerializer.send(element, *el.as_input)
          end
          @injected_elements = Elements.as_options_for(
            Helpers.pick(@allowed_elements)
          )

          injected_options = Helpers.random_options(with: {
            serializer: UserSerializer,
            element.plural.to_sym => @injected_elements
          })
          @element_klass = Object.const_get("SimpleAMS::Document::#{element.plural.capitalize}").new(
            SimpleAMS::Options.new(User.new, injected_options: injected_options)
          )
        end

        it "holds the uniq union of injected and allowed #{element.plural}" do
          elements_expected = (Elements.as_elements_for(
            @injected_elements, klass: Object.const_get("Elements::#{element.capitalize}")
          ) + @allowed_elements).uniq{|q| q.name}.select{|el|
            @allowed_elements.map(&:name).include?(el.name) && @injected_elements.keys.include?(el.name)
          }

          elements_expected.each do |element_expected|
            element_got = @element_klass[element_expected.name]
            expect(element_got.name).to eq(element_expected.name)
            expect(element_got.value).to eq(element_expected.value)
            expect(element_got.options).to eq(element_expected.options)
          end
        end
      end
    end
  end
end
