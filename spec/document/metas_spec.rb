require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Document, 'metas' do
  context "with no metas in general" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
          }).tap{|h| h.delete(:metas)}
        )
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.metas.members).to eq []
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.metas).to respond_to(:each)
        @document.metas.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with no injected metas" do
    before do
      @allowed_metas = Elements.metas
      @allowed_metas.each do |meta|
        UserSerializer.meta(*meta.as_input)
      end

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer
          }).tap{|h| h.delete(:metas)}
        )
      )

      @uniq_allowed_metas = @allowed_metas.uniq{|l| l.name}
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.metas.members).not_to eq []
      end
    end

    it "returns the allowed ones" do
      expect(@document.metas.map(&:name)).to eq @uniq_allowed_metas.map(&:name)
      expect(@document.metas.map(&:value)).to eq @uniq_allowed_metas.map(&:value)
      expect(@document.metas.map(&:options)).to eq @uniq_allowed_metas.map(&:options)
    end
  end

  context "with empty injected metas" do
    before do
      @allowed_metas = Elements.metas
      @allowed_metas.each do |meta|
        UserSerializer.meta(*meta.as_input)
      end

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
            metas: []
          })
        )
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.metas.members).to eq []
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.metas).to respond_to(:each)
        @document.metas.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with no allowed metas but injected ones" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
          })
        )
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.metas.members).to eq []
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.metas).to respond_to(:each)
        @document.metas.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with various injected metas" do
    before do
      @allowed_metas = Elements.metas
      @allowed_metas.each do |meta|
        UserSerializer.meta(*meta.as_input)
      end
      @injected_metas = Elements.as_options_for(
        Helpers.pick(@allowed_metas)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        metas: @injected_metas
      })
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: injected_options
        )
      )
    end

    it "holds the uniq union of injected and allowed metas" do
      metas_got = @document.metas
      metas_expected = (@allowed_metas + Elements.as_elements_for(
        @injected_metas, klass: Elements::Link
      )).uniq{|q| q.name}.select{|l|
        @allowed_metas.map(&:name).include?(l.name) && @injected_metas.keys.include?(l.name)
      }

      expect(metas_got.map(&:name)).to eq(metas_expected.map(&:name))
      expect(metas_got.map(&:value)).to eq(metas_expected.map(&:value))
      expect(metas_got.map(&:options)).to eq(metas_expected.map(&:options))
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
        Helpers.pick(@allowed_metas)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        metas: @injected_metas
      })
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: injected_options
        )
      )
    end

    it "holds the uniq union of injected and allowed metas" do
      metas_got = @document.metas
      metas_expected = (@allowed_metas + Elements.as_elements_for(
        @injected_metas, klass: Elements::Link
      )).uniq{|q| q.name}.select{|l|
        @allowed_metas.map(&:name).include?(l.name) && @injected_metas.keys.include?(l.name)
      }

      expect(metas_got.map(&:name)).to eq(metas_expected.map(&:name))
      expect(metas_got.map(&:value)).to eq(metas_expected.map(&:value))
      expect(metas_got.map(&:options)).to eq(metas_expected.map(&:options))
    end
  end
end

