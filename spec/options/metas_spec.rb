require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Options, 'metas' do
  context "with no metas in general" do
    before do
      @options = SimpleAMS::Options.new(
        resource: User.new,
        injected_options: Helpers.random_options_with({
          serializer: UserSerializer,
        }).tap{|h| h.delete(:metas)}
      )
    end

    it "returns empty metas array" do
      expect(@options.metas).to eq []
    end
  end

  context "with no injected metas" do
    before do
      @allowed_metas = Elements.metas
      @allowed_metas.each do |meta|
        UserSerializer.meta(*meta.as_input)
      end

      @options = SimpleAMS::Options.new(
        resource: User.new,
        injected_options: Helpers.random_options_with({
          serializer: UserSerializer
        }).tap{|h| h.delete(:metas)}
      )

      @uniq_allowed_metas = @allowed_metas.uniq{|l| l.name}
    end

    it "returns the allowed ones" do
      expect(@options.metas.map(&:name)).to eq @uniq_allowed_metas.map(&:name)
      expect(@options.metas.map(&:value)).to eq @uniq_allowed_metas.map(&:value)
      expect(@options.metas.map(&:options)).to eq @uniq_allowed_metas.map(&:options)
    end
  end

  context "with empty injected metas" do
    before do
      @allowed_metas = Elements.metas
      @allowed_metas.each do |meta|
        UserSerializer.meta(*meta.as_input)
      end

      @options = SimpleAMS::Options.new(
        resource: User.new,
        injected_options: Helpers.random_options_with({
          serializer: UserSerializer,
          metas: []
        })
      )
    end

    it "returns empty metas array" do
      expect(@options.metas).to eq []
    end
  end

  context "with no allowed metas but injected ones" do
    before do
      @options = SimpleAMS::Options.new(
        resource: User.new,
        injected_options: Helpers.random_options_with({
          serializer: UserSerializer,
        })
      )
    end

    it "returns empty metas array" do
      expect(@options.metas).to eq []
    end
  end

  context "with various injected metas" do
    before do
      @allowed_metas = Elements.metas
      @allowed_metas.each do |meta|
        UserSerializer.meta(*meta.as_input)
      end
      @injected_metas = Elements.as_options_for(
        Helpers.pick(@allowed_metas, length: rand(@allowed_metas.length) + 1)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        metas: @injected_metas
      })
      @options = SimpleAMS::Options.new(
        resource: User.new,
        injected_options: injected_options
      )
    end

    it "holds the uniq union of injected and allowed metas" do
      expect(@options.metas.map(&:name)).to(
        eq(
          Elements.as_elements_for(
            @injected_metas, klass: Elements::Meta
          ).map(&:name) & @allowed_metas.map(&:name)
        )
      )
    end
  end

  context "with repeated (allowed) metas" do
    before do
      @allowed_metas = Elements.metas
      2.times{
        @allowed_metas.each do |meta|
          UserSerializer.meta(*meta.as_input)
        end
      }
      @injected_metas = Elements.as_options_for(
        Helpers.pick(@allowed_metas, length: rand(@allowed_metas.length) + 1)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        metas: @injected_metas
      })
      @options = SimpleAMS::Options.new(
        resource: User.new,
        injected_options: injected_options
      )
    end

    it "holds the uniq union of injected and allowed metas" do
      expect(@options.metas.map(&:name)).to(
        eq(
          Elements.as_elements_for(
            @injected_metas, klass: Elements::Meta
          ).map(&:name) & @allowed_metas.map(&:name)
        )
      )
    end
  end

  context "with lambda" do
    context "allowed metas" do
      before do
        @user = User.new
        @allowed_metas = [
          Elements::Meta.new(
            name: :user, value: ->(obj){
              ["#{@user.id}", collection: :yes]
            }
          ),
          Elements::Meta.new(
            name: :root, value: "something", options: {collection: :no}
          ),
        ]
        @allowed_metas.each do |meta|
          UserSerializer.meta(*meta.as_input)
        end

        @options = SimpleAMS::Options.new(
          resource: @user,
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }, without: [:metas])
        )
      end

      it "holds the unwrapped metas" do
        expect(@options.metas.count).to eq(2)

        expect(@options.metas.first.name).to eq(@allowed_metas.first.name)
        expect(@options.metas.first.value).to eq(@allowed_metas.first.value.call(@user).first)
        expect(@options.metas.first.options).to eq(@allowed_metas.first.value.call(@user).last)

        expect(@options.metas.last.name).to eq(@allowed_metas.last.name)
        expect(@options.metas.last.value).to eq(@allowed_metas.last.value)
        expect(@options.metas.last.options).to eq(@allowed_metas.last.options)
      end
    end

    context "injected metas" do
      before do
        @user = User.new
        @allowed_metas = Elements.metas
        @allowed_metas.each do |meta|
          UserSerializer.meta(*meta.as_input)
        end

        #@injected_metas = Helpers.pick(@allowed_metas).inject({}) { |memo, meta|
        @injected_metas = [@allowed_metas.first].inject({}) { |memo, meta|
          memo[meta.name] = ->(obj){ ["#{@user.id}/#{meta.name}", rel: meta.name] }
          memo
        }

        @options = SimpleAMS::Options.new(
          resource: @user,
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            metas: @injected_metas
          })
        )
      end

      it "holds the injected lambda metas" do
        expect(@options.metas.count).to eq(@injected_metas.count)

        @options.metas.each do |meta|
          expect(meta.name).to eq(@injected_metas.find{|l| l.first == meta.name}[0])
          expect(meta.value).to eq(@injected_metas[meta.name].call(@user).first)
        end
      end
    end
  end
end
