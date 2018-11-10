require "spec_helper"

RSpec.describe SimpleAMS::Document::Folder, 'value_hash' do
  [:type, :primary_id, :adapter].map(&:to_s).each do |element|
    element.send(:extend, Module.new{
      def type?
        self.to_sym == :type
      end

      def primary_id?
        self.to_sym == :primary_id
      end

      def adapter?
        self.to_sym == :adapter
      end

      def default_name(resource: false)
        if self.to_sym == :type && resource
          return :user if self.to_sym == :type
        else
          return :user_collection if self.to_sym == :type
        end

        return :id if self.to_sym == :primary_id
        return SimpleAMS::Adapters::AMS if self.to_sym == :adapter
      end

      def default_options
        return {_explicit: true} if self.to_sym == :type
        return {}
      end
    })

    resource_options = -> {
      it "defaults to class name" do
        @folder.each do |document|
          expect(document.send(element).name).to(
            eq element.default_name(resource: true)
          )
        end
      end
    }

    describe "(#{element})" do
      context "with no #{element} is specified" do
        before do
          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(User.array, {
              injected_options: {
                collection: Helpers.random_options(without: [element.to_sym]),
                serializer: UserSerializer,
              }
            })
          )
        end

        instance_exec(&resource_options)

        it "defaults to class name" do
          expect(@folder.send(element).name).to eq element.default_name
        end

        if element.type?
          it "updates name correctly" do
            expect(@folder.name).to eq @folder.send(element).name
          end
        end

        if element.primary_id?
          it "value defaults to resource id" do
            expect(@folder.send(element).value).to eq @folder.resource.id
          end
        end
      end

      context "with no injected #{element}" do
        before do
          @element = Elements.send(element, value: :an_element, options: {foo: :bar})
          [@element].each do |el|
            UserSerializer.collection do
              self.send(element, *el.as_input)
            end
          end

          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(User.array, {
              injected_options: {
                collection: Helpers.random_options(without: [element.to_sym]),
                serializer: UserSerializer,
              }
            })
          )
        end

        instance_exec(&resource_options)

        if element.adapter?
          it "for #{element}: returns the resource's #{element} specified" do
          #adapter is taken from resource options and can't be overrided
          #it doesn't really make any sense,
          #if you need custom behavior on collection, override the adapter instead
            expect(@folder.send(element).name).to eq SimpleAMS::Adapters::AMS
            expect(@folder.send(element).options).to(
              eq({}.merge(element.default_options))
            )
          end
        else
          it "returns the #{element} specified" do
            expect(@folder.send(element).name).to eq :an_element
            expect(@folder.send(element).options).to(
              eq({foo: :bar}.merge(element.default_options))
            )
          end
        end

        if element.type?
          it "updates name correctly" do
            expect(@folder.name).to eq @folder.send(element).name
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

          _element = Elements.send(element, value: :an_element, options: {foo: :bar})
          UserSerializer.collection do
            self.send(element, *_element.as_input)
          end

          @element = Elements.send(element, value: :another_element, options: {bar: :foo})
          @folder = SimpleAMS::Document::Folder.new(
            SimpleAMS::Options.new(User.array, {
              injected_options: {
                collection: Helpers.random_options(with: {
                  element.to_sym => @element.as_input
                }),
                serializer: UserSerializer
              }
            })
          )
        end

        if element.primary_id?
          after do
            UserSerializer.send(:remove_method, :an_element)
            UserSerializer.send(:remove_method, :another_element)
          end
        end

        if element.adapter?
          it "for #{element}: returns the resource's #{element} specified" do
            expect(@folder.send(element).name).to eq SimpleAMS::Adapters::AMS
            expect(@folder.send(element).options).to eq({})
          end
        else
          it "returns the #{element} specified" do
            expect(@folder.send(element).name).to eq @element.value
            expect(@folder.send(element).options).to eq(@element.options)
          end
        end

        if element.type?
          it "updates name correctly" do
            expect(@folder.name).to eq @folder.send(element).name
          end
        end

        if element.primary_id?
          it "value resource's value" do
            expect(@folder.send(element).value).to eq 'another_element_value'
          end
        end
      end

      context "with lambda" do
        context "allowed #{element}" do
          before do
            @users = User.array
            @allowed_element = Object.const_get(
              "#{Elements}::#{element.split('_').map(&:capitalize).join}"
            ).new(
              value: if element.primary_id?
                       ->(obj, s){ [@_user_attr ||= :id, {foo: :bar}] }
                     else
                       ->(obj, s){ [obj.id, {foo: :bar}] }
                     end
            )
            [@allowed_element].each do |el|
              UserSerializer.collection do
                self.send(element, *el.as_lambda_input)
              end
            end

            options = SimpleAMS::Options.new(@users, {
              injected_options: {
                collection: Helpers.random_options(without: [element.to_sym]),
                serializer: UserSerializer
              }
            })

            @folder = SimpleAMS::Document::Folder.new(options)
          end

          if element.adapter?
            it "holds the resource's #{element}" do
              expect(@folder.send(element).value).to eq(SimpleAMS::Adapters::AMS)
              expect(@folder.send(element).options).to eq({})
            end
          else
            it "holds the unwrapped #{element}" do
              if element.primary_id?
                expect(@folder.send(element).value).to(
                  eq(@users.send(@allowed_element.value.call(@users, nil).first))
                )
              else
                expect(@folder.send(element).value).to(
                  eq(@allowed_element.value.call(@users, nil).first)
                )
              end
              expect(@folder.send(element).options).to(
                eq(@allowed_element.value.call(@users, nil).last.merge(element.default_options))
              )
            end
          end
        end

        context "injected #{element}" do
          before do
            @user = User.new
            @allowed_element = Elements.send(element)
            [@allowed_element].each do |el|
              UserSerializer.collection do
                self.send(element, *el.as_input)
              end
            end

            if element.primary_id?
              @injected_element = ->(obj, s){ [@_user_attr ||= obj.class.model_attributes.sample, {foo: :bar}] }
            else
              @injected_element = ->(obj, s){ ["/api/v1/#{obj.id}", rel: :foobar] }
            end

            options = SimpleAMS::Options.new(@user, {
              injected_options: {
                collection: Helpers.random_options(with: {
                  element.to_sym => @injected_element
                }),
                serializer: UserSerializer,
              }
            })

            @folder = SimpleAMS::Document::Folder.new(options)
          end

          if element.adapter?
            it "holds the resource's #{element}" do
              expect(@folder.send(element).value).to eq(SimpleAMS::Adapters::AMS)
              expect(@folder.send(element).options).to eq({})
            end
          else
            it "holds the injected lambda #{element}" do
              if element.primary_id?
                expect(@folder.send(element).value).to(
                  eq(@user.send(@injected_element.call(@user, nil).first))
                )
              else
                expect(@folder.send(element).value).to(
                  eq(@injected_element.call(@user, nil).first)
                )
              end
              expect(@folder.send(element).options).to(
                eq(@injected_element.call(@user, nil).last)
              )
            end
          end
        end
      end
    end
  end
end
