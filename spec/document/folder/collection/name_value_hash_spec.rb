require 'spec_helper'

RSpec.describe SimpleAMS::Document::Folder, '(collection) name_value_hash' do
  %i[generic link meta form].map(&:to_s).each do |element|
    element.send(:extend, Module.new do
      def plural
        "#{self}s"
      end
    end)

    describe "(#{element.plural})" do
      context "with no #{element.plural} in general" do
        before do
          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(
              User.array,
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer
              }).tap { |h| h.delete(element.to_sym) }
            )
          )
        end

        describe 'members' do
          it 'returns an empty array' do
            @folder.each do |document|
              expect(document.send(element.plural)).to eq({})
            end
          end
        end

        describe 'values' do
          it 'returns an empty array' do
            @folder.each do |document|
              expect(document.send(element.plural)).to respond_to(:each)
              document.send(element.plural).each do |_field|
                raise('this should never happen as fields should be empty')
              end
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

          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(
              User.array,
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer
              }).tap { |h| h.delete(element.plural.to_sym) }
            )
          )

          @uniq_allowed_elements = @allowed_elements.uniq(&:name)
        end

        describe 'members' do
          it 'returns an empty array' do
            @folder.each do |document|
              expect(document.send(element.plural)).not_to eq({})
            end
          end
        end

        it 'returns the allowed ones' do
          @folder.each do |document|
            expect(document.send(element.plural).map(&:name)).to eq @uniq_allowed_elements.map(&:name)
            expect(document.send(element.plural).map(&:value)).to eq @uniq_allowed_elements.map(&:value)
            expect(document.send(element.plural).map(&:options)).to eq @uniq_allowed_elements.map(&:options)
          end
        end
      end

      context "with empty injected #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          @allowed_elements.each do |el|
            UserSerializer.send(element, *el.as_input)
          end

          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(
              User.array,
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
                element.plural.to_sym => []
              })
            )
          )
        end

        describe 'members' do
          it 'returns an empty array' do
            @folder.each do |document|
              expect(document.send(element.plural)).to(eq({}))
            end
          end
        end

        describe 'values' do
          it 'returns an empty array' do
            @folder.each do |document|
              expect(document.send(element.plural)).to respond_to(:each)
              document.send(element.plural).each do |_field|
                raise('this should never happen as fields should be empty')
              end
            end
          end
        end
      end

      context "with no allowed #{element.plural} but injected ones" do
        before do
          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(
              User.array,
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer
              })
            )
          )
        end

        describe 'members' do
          it 'returns an empty array' do
            @folder.each do |document|
              expect(document.send(element.plural)).to eq({})
            end
          end
        end

        describe 'values' do
          it 'returns an empty array' do
            @folder.each do |document|
              expect(document.send(element.plural)).to respond_to(:each)
              document.send(element.plural).each do |_field|
                raise('this should never happen as fields should be empty')
              end
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
          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(User.array, injected_options: injected_options)
          )
        end

        it "holds the uniq union of injected and allowed #{element.plural}" do
          @folder.each do |document|
            elements_got = document.send(element.plural)
            elements_expected = (Elements.as_elements_for(
              @injected_elements, klass: Object.const_get("Elements::#{element.capitalize}")
            ) + @allowed_elements).uniq(&:name).select do |l|
              @allowed_elements.map(&:name).include?(l.name) && @injected_elements.keys.include?(l.name)
            end

            expect(elements_got.map(&:name)).to eq(elements_expected.map(&:name))
            expect(elements_got.map(&:value)).to eq(elements_expected.map(&:value))
            expect(elements_got.map(&:options).count).to eq(elements_expected.map(&:options).count)
            expect(elements_got.map(&:options)).to eq(elements_expected.map(&:options))
          end
        end
      end

      context "with repeated (allowed) #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          2.times do
            @allowed_elements.each do |el|
              UserSerializer.send(element, *el.as_input)
            end
          end
          @injected_elements = Elements.as_options_for(
            Helpers.pick(@allowed_elements)
          )

          injected_options = Helpers.random_options(with: {
            serializer: UserSerializer,
            element.plural.to_sym => @injected_elements
          })
          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(User.array, injected_options: injected_options)
          )
        end

        it "holds the uniq union of injected and allowed #{element.plural}" do
          @folder.each do |document|
            elements_got = document.send(element.plural)
            _injected_elements = Elements.as_elements_for(
              @injected_elements, klass: Object.const_get("Elements::#{element.capitalize}")
            )

            elements_expected = (_injected_elements.map(&:name) & @allowed_elements.map(&:name)).map do |name|
              _injected_elements.find { |el| el.name == name }
            end

            expect(elements_got.map(&:name)).to eq(elements_expected.map(&:name))
            expect(elements_got.map(&:value)).to eq(elements_expected.map(&:value))
            expect(elements_got.map(&:options)).to eq(elements_expected.map(&:options))
          end
        end
      end

      context 'with lambda' do
        context "allowed #{element.plural}" do
          before do
            @users = User.array
            @allowed_elements = [
              Object.const_get("#{Elements}::#{element.capitalize}").new(
                name: :user, value: lambda { |obj, _s|
                  ["api/v1/users/#{obj.id}", { rel: :user }]
                }
              ),
              Object.const_get("#{Elements}::#{element.capitalize}").new(
                name: :root, value: 'api/v1/root', options: { rel: :root }
              )
            ]
            @allowed_elements.each do |el|
              UserSerializer.send(element, *el.as_input)
            end

            options = SimpleAMS::Options.new(
              @users,
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer
              }, without: [element.plural.to_sym])
            )

            @folder = SimpleAMS::Document::Folder.new(options)
          end

          it "holds the unwrapped #{element.plural}" do
            @folder.each do |document|
              expect(document.send(element.plural).count).to eq(2)

              expect(document.send(element.plural).first.name).to(
                eq(@allowed_elements.first.name)
              )
              expect(document.send(element.plural).first.value).to(
                eq(@allowed_elements.first.value.call(document.resource, nil).first)
              )
              expect(document.send(element.plural).first.options).to(
                eq(@allowed_elements.first.value.call(document.resource, nil).last)
              )

              expect(document.send(element.plural).map.to_a.last.name).to eq(@allowed_elements.last.name)
              expect(document.send(element.plural).map.to_a.last.value).to eq(@allowed_elements.last.value)
              expect(document.send(element.plural).map.to_a.last.options).to eq(@allowed_elements.last.options)
            end
          end
        end

        context "injected #{element.plural}" do
          before do
            @users = User.array
            @allowed_elements = Elements.send(element.plural)
            @allowed_elements.each do |el|
              UserSerializer.send(element, *el.as_input)
            end

            @injected_elements = [@allowed_elements.first].each_with_object({}) do |el, memo|
              memo[el.name] = ->(obj, _s) { ["/api/v1/#{obj.id}/#{el.name}", { rel: el.name }] }
            end

            options = SimpleAMS::Options.new(
              @users,
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
                element.plural.to_sym => @injected_elements
              })
            )

            @folder = SimpleAMS::Document::Folder.new(options)
          end

          it "holds the injected lambda #{element.plural}" do
            @folder.each do |document|
              expect(document.send(element.plural).count).to eq(@injected_elements.count)

              document.send(element.plural).each do |el|
                expect(el.name).to eq(@injected_elements.find { |l| l.first == el.name }[0])
                expect(el.value).to eq(@injected_elements[el.name].call(document.resource, nil).first)
              end
            end
          end
        end
      end
    end
  end
end
