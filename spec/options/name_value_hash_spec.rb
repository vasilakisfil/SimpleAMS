require "spec_helper"

#these tests have been replicated from links, so some options make sense only for links
#but this shouldn't affect the tests' effeciency
RSpec.describe SimpleAMS::Options, 'name_value_hash' do
  [:generic, :link, :meta, :form].map(&:to_s).each do |element|
    element.send(:extend, Module.new {
      def plural
        "#{self.to_s}s"
      end
    })

    describe "(#{element.plural})" do
      context "with no #{element.plural} in general" do
        before do
          @options = SimpleAMS::Options.new(User.new, {
            injected_options: Helpers.random_options(with:{
              serializer: UserSerializer,
            }).tap { |h| h.delete(element.to_sym) }
          })
        end

        it "returns empty #{element.plural} array" do
          expect(@options.send(element.plural)).to eq []
        end
      end

      context "with no injected #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          @allowed_elements.each do |el|
            UserSerializer.send(element, *el.as_input)
          end

          @options = SimpleAMS::Options.new(User.new, {
            injected_options: Helpers.random_options(with:{
              serializer: UserSerializer
            }).tap { |h| h.delete(element.plural.to_sym) }
          })

          @uniq_allowed_elements = @allowed_elements.uniq { |l| l.name }
        end

        it "returns the allowed ones" do
          expect(@options.send(element.plural).map(&:name)).to eq @uniq_allowed_elements.map(&:name)
          expect(@options.send(element.plural).map(&:value)).to eq @uniq_allowed_elements.map(&:value)
          expect(@options.send(element.plural).map(&:options)).to eq @uniq_allowed_elements.map(&:options)
        end
      end

      context "with empty injected #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          @allowed_elements.each do |el|
            UserSerializer.send(element, *el.as_input)
          end

          @options = SimpleAMS::Options.new(User.new, {
            injected_options: Helpers.random_options(with:{
              serializer: UserSerializer,
              element.plural.to_sym => []
            })
          })
        end

        it "returns empty #{element.plural} array" do
          expect(@options.send(element.plural)).to eq []
        end
      end

      context "with no allowed #{element.plural} but injected ones" do
        before do
          @options = SimpleAMS::Options.new(User.new, {
            injected_options: Helpers.random_options(with:{
              serializer: UserSerializer,
            })
          })
        end

        it "returns empty #{element.plural} array" do
          expect(@options.send(element.plural)).to eq []
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

          injected_options = Helpers.random_options(with:{
            serializer: UserSerializer,
            element.plural.to_sym => @injected_elements
          })
          @options = SimpleAMS::Options.new(User.new, {
            injected_options: injected_options
          })
        end

        it "holds the uniq union of injected and allowed #{element.plural}" do
          elements_got = @options.send(element.plural)
          _injected_elements = Elements.as_elements_for(
            @injected_elements, klass: Object.const_get("#{Elements}::#{element.capitalize}")
          )

          elements_expected = (_injected_elements.map(&:name) & @allowed_elements.map(&:name)).map { |name|
            _injected_elements.find { |l| l.name == name }
          }

          expect(elements_got.map(&:name)).to eq(elements_expected.map(&:name))
          expect(elements_got.map(&:value)).to eq(elements_expected.map(&:value))
          expect(elements_got.map(&:options)).to eq(elements_expected.map(&:options))
        end
      end

      context "with repeated (allowed) #{element.plural}" do
        before do
          @allowed_elements = Elements.send(element.plural)
          2.times {
            @allowed_elements.each do |el|
              UserSerializer.send(element, *el.as_input)
            end
          }
          @injected_elements = Elements.as_options_for(
            Helpers.pick(@allowed_elements)
          )

          injected_options = Helpers.random_options(with:{
            serializer: UserSerializer,
            element.plural.to_sym => @injected_elements
          })
          @options = SimpleAMS::Options.new(User.new, {
            injected_options: injected_options
          })
        end

        it "holds the uniq union of injected and allowed #{element.plural}" do
          elements_got = @options.send(element.plural)
          _injected_elements = Elements.as_elements_for(
            @injected_elements, klass: Object.const_get("#{Elements}::#{element.capitalize}")
          )

          elements_expected = (_injected_elements.map(&:name) & @allowed_elements.map(&:name)).map { |name|
            _injected_elements.find { |l| l.name == name }
          }

          expect(elements_got.map(&:name)).to eq(elements_expected.map(&:name))
          expect(elements_got.map(&:value)).to eq(elements_expected.map(&:value))
          expect(elements_got.map(&:options)).to eq(elements_expected.map(&:options))
        end
      end

      context "with lambda" do
        context "allowed #{element.plural}" do
          before do
            @user = User.new
            @allowed_elements = [
              Object.const_get("#{Elements}::#{element.capitalize}").new(
                name: :user, value: ->(obj, s) {
                  ["api/v1/users/#{obj.id}", { rel: :user }]
                }
              ),
              Object.const_get("#{Elements}::#{element.capitalize}").new(
                name: :root, value: "api/v1/root", options: { rel: :root }
              ),
            ]
            @allowed_elements.each do |el|
              UserSerializer.send(element, *el.as_input)
            end

            @options = SimpleAMS::Options.new(@user, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer
              }, without: [element.plural.to_sym])
            })
          end

          it "holds the unwrapped #{element.plural}" do
            expect(@options.send(element.plural).count).to eq(2)

            expect(@options.send(element.plural).first.name).to(
              eq(@allowed_elements.first.name)
            )
            expect(@options.send(element.plural).first.value).to(
              eq(@allowed_elements.first.value.call(@user, nil).first)
            )
            expect(@options.send(element.plural).first.options).to(
              eq(@allowed_elements.first.value.call(@user, nil).last)
            )

            expect(@options.send(element.plural).last.name).to eq(@allowed_elements.last.name)
            expect(@options.send(element.plural).last.value).to eq(@allowed_elements.last.value)
            expect(@options.send(element.plural).last.options).to eq(@allowed_elements.last.options)
          end
        end

        context "injected #{element.plural}" do
          before do
            @user = User.new
            @allowed_elements = Elements.send(element.plural)
            @allowed_elements.each do |el|
              UserSerializer.send(element, *el.as_input)
            end

            @injected_elements = [@allowed_elements.first].inject({}) { |memo, el|
              memo[el.name] = ->(obj, s) { ["/api/v1/#{@user.id}/#{el.name}", rel: el.name] }
              memo
            }

            @options = SimpleAMS::Options.new(@user, {
              injected_options: Helpers.random_options(with: {
                serializer: UserSerializer,
                element.plural.to_sym => @injected_elements
              })
            })
          end

          it "holds the injected lambda #{element.plural}" do
            expect(@options.send(element.plural).count).to eq(@injected_elements.count)

            @options.send(element.plural).each do |el|
              expect(el.name).to eq(@injected_elements.find { |l| l.first == el.name }[0])
              expect(el.value).to eq(@injected_elements[el.name].call(@user, nil).first)
            end
          end
        end
      end
    end
  end
end
