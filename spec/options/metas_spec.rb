require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Options, 'metas' do
  context "with no metas in general" do
    before do
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
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
        User.new,
        Helpers.random_options_with({
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
        User.new,
        Helpers.random_options_with({
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
        User.new,
        Helpers.random_options_with({
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
        @allowed_metas.sample(rand(@allowed_metas.length) + 1)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        metas: @injected_metas
      })
      @options = SimpleAMS::Options.new(
        User.new,
        injected_options
      )
    end

    it "holds the uniq union of injected and allowed metas" do
      expect(@options.metas.map(&:name)).to(
        eq(
          @allowed_metas.map(&:name) & Elements.as_elements_for(
            @injected_metas, klass: Elements::Meta
          ).map(&:name)
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
        @allowed_metas.sample(rand(@allowed_metas.length) + 1)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        metas: @injected_metas
      })
      @options = SimpleAMS::Options.new(
        User.new,
        injected_options
      )
    end

    it "holds the uniq union of injected and allowed metas" do
      expect(@options.metas.map(&:name)).to(
        eq(
          @allowed_metas.map(&:name) & Elements.as_elements_for(
            @injected_metas, klass: Elements::Meta
          ).map(&:name)
        )
      )
    end
  end
end
