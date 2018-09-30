require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Options, 'generics' do
  context "with no generics in general" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap{|h| h.delete(:generics)}
      })
    end

    it "returns empty generics array" do
      expect(@options.generics).to eq []
    end
  end

  context "with no injected generics" do
    before do
      @allowed_generics = Elements.generics
      @allowed_generics.each do |generic|
        UserSerializer.generic(*generic.as_input)
      end

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer
        }).tap{|h| h.delete(:generics)}
      })

      @uniq_allowed_generics = @allowed_generics.uniq{|l| l.name}
    end

    it "returns the allowed ones" do
      expect(@options.generics.map(&:name)).to eq @uniq_allowed_generics.map(&:name)
      expect(@options.generics.map(&:value)).to eq @uniq_allowed_generics.map(&:value)
      expect(@options.generics.map(&:options)).to eq @uniq_allowed_generics.map(&:options)
    end
  end

  context "with empty injected generics" do
    before do
      @allowed_generics = Elements.generics
      @allowed_generics.each do |generic|
        UserSerializer.generic(*generic.as_input)
      end

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          generics: []
        })
      })
    end

    it "returns empty generics array" do
      expect(@options.generics).to eq []
    end
  end

  context "with no allowed generics but injected ones" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        })
      })
    end

    it "returns empty generics array" do
      expect(@options.generics).to eq []
    end
  end

  context "with various injected generics" do
    before do
      @allowed_generics = Elements.generics
      @allowed_generics.each do |generic|
        UserSerializer.generic(*generic.as_input)
      end
      @injected_generics = Elements.as_options_for(
        Helpers.pick(@allowed_generics)
      )

      injected_options = Helpers.random_options(with:{
        serializer: UserSerializer,
        generics: @injected_generics
      })
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: injected_options
      })
    end

    it "holds the uniq union of injected and allowed generics" do
      generics_got = @options.generics
      _injected_generics = Elements.as_elements_for(
        @injected_generics, klass: Elements::Generic
      )

      generics_expected = (_injected_generics.map(&:name) & @allowed_generics.map(&:name)).map{|name|
        _injected_generics.find{|l| l.name == name}
      }

      expect(generics_got.map(&:name)).to eq(generics_expected.map(&:name))
      expect(generics_got.map(&:value)).to eq(generics_expected.map(&:value))
      expect(generics_got.map(&:options)).to eq(generics_expected.map(&:options))
    end
  end

  context "with repeated (allowed) generics" do
    before do
      @allowed_generics = Elements.generics
      2.times{
        @allowed_generics.each do |generic|
          UserSerializer.generic(*generic.as_input)
        end
      }
      @injected_generics = Elements.as_options_for(
        Helpers.pick(@allowed_generics)
      )

      injected_options = Helpers.random_options(with:{
        serializer: UserSerializer,
        generics: @injected_generics
      })
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: injected_options
      })
    end

    it "holds the uniq union of injected and allowed generics" do
      generics_got = @options.generics
      _injected_generics = Elements.as_elements_for(
        @injected_generics, klass: Elements::Generic
      )

      generics_expected = (_injected_generics.map(&:name) & @allowed_generics.map(&:name)).map{|name|
        _injected_generics.find{|l| l.name == name}
      }

      expect(generics_got.map(&:name)).to eq(generics_expected.map(&:name))
      expect(generics_got.map(&:value)).to eq(generics_expected.map(&:value))
      expect(generics_got.map(&:options)).to eq(generics_expected.map(&:options))
    end
  end

  context "with lambda" do
    context "allowed generics" do
      before do
        @user = User.new
        @allowed_generics = [
          Elements::Generic.new(
            name: :user, value: ->(obj, s){
              ["api/v1/users/#{@user.id}", {rel: :user}]
            }
          ),
          Elements::Generic.new(
            name: :root, value: "api/v1/root", options: {rel: :root}
          ),
        ]
        @allowed_generics.each do |generic|
          UserSerializer.generic(*generic.as_input)
        end

        @options = SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }, without: [:generics])
        })
      end

      it "holds the unwrapped generics" do
        expect(@options.generics.count).to eq(2)

        expect(@options.generics.first.name).to eq(@allowed_generics.first.name)
        expect(@options.generics.first.value).to eq(@allowed_generics.first.value.call(@user, nil).first)
        expect(@options.generics.first.options).to eq(@allowed_generics.first.value.call(@user, nil).last)

        expect(@options.generics.last.name).to eq(@allowed_generics.last.name)
        expect(@options.generics.last.value).to eq(@allowed_generics.last.value)
        expect(@options.generics.last.options).to eq(@allowed_generics.last.options)
      end
    end

    context "injected generics" do
      before do
        @user = User.new
        @allowed_generics = Elements.generics
        @allowed_generics.each do |generic|
          UserSerializer.generic(*generic.as_input)
        end

        #@injected_generics = Helpers.pick(@allowed_generics).inject({}) { |memo, generic|
        @injected_generics = [@allowed_generics.first].inject({}) { |memo, generic|
          memo[generic.name] = ->(obj, s){ ["/api/v1/#{@user.id}/#{generic.name}", rel: generic.name] }
          memo
        }

        @options = SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            generics: @injected_generics
          })
        })
      end

      it "holds the injected lambda generics" do
        expect(@options.generics.count).to eq(@injected_generics.count)

        @options.generics.each do |generic|
          expect(generic.name).to eq(@injected_generics.find{|l| l.first == generic.name}[0])
          expect(generic.value).to eq(@injected_generics[generic.name].call(@user, nil).first)
        end
      end
    end
  end
end


