require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Document, 'generics' do
  context "with no generics in general" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
          }).tap{|h| h.delete(:generics)}
        })
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.generics).to eq({})
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.generics).to respond_to(:each)
        @document.generics.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with no injected generics" do
    before do
      @allowed_generics = Elements.generics
      @allowed_generics.each do |generic|
        UserSerializer.generic(*generic.as_input)
      end

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }).tap{|h| h.delete(:generics)}
        })
      )

      @uniq_allowed_generics = @allowed_generics.uniq{|l| l.name}
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.generics).not_to eq({})
      end
    end

    it "returns the allowed ones" do
      expect(@document.generics.map(&:name)).to eq @uniq_allowed_generics.map(&:name)
      expect(@document.generics.map(&:value)).to eq @uniq_allowed_generics.map(&:value)
      expect(@document.generics.map(&:options)).to eq @uniq_allowed_generics.map(&:options)
    end
  end

  context "with empty injected generics" do
    before do
      @allowed_generics = Elements.generics
      @allowed_generics.each do |generic|
        UserSerializer.generic(*generic.as_input)
      end

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            generics: []
          })
        })
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.generics).to eq({})
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.generics).to respond_to(:each)
        @document.generics.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with no allowed generics but injected ones" do
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
        expect(@document.generics).to eq({})
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.generics).to respond_to(:each)
        @document.generics.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
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

      injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        generics: @injected_generics
      })
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, injected_options: injected_options)
      )
    end

    it "holds the uniq union of injected and allowed generics" do
      generics_got = @document.generics
      generics_expected = (Elements.as_elements_for(
        @injected_generics, klass: Elements::Generic
      ) + @allowed_generics).uniq{|q| q.name}.select{|l|
        @allowed_generics.map(&:name).include?(l.name) && @injected_generics.keys.include?(l.name)
      }

      expect(generics_got.map(&:name)).to eq(generics_expected.map(&:name))
      expect(generics_got.map(&:value)).to eq(generics_expected.map(&:value))
      expect(generics_got.map(&:options).count).to eq(generics_expected.map(&:options).count)
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

      injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        generics: @injected_generics
      })
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, injected_options: injected_options)
      )
    end

    it "holds the uniq union of injected and allowed generics" do
      generics_got = @document.generics
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

  context "accessing a generic through Document::Generic class" do
    before do
      @allowed_generics = Elements.generics
      @allowed_generics.each do |generic|
        UserSerializer.generic(*generic.as_input)
      end
      @injected_generics = Elements.as_options_for(
        Helpers.pick(@allowed_generics)
      )

      injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        generics: @injected_generics
      })
      @generic_klass = SimpleAMS::Document::Generics.new(
        SimpleAMS::Options.new(User.new, injected_options: injected_options)
      )
    end

    it "holds the uniq union of injected and allowed generics" do
      generics_expected = (Elements.as_elements_for(
        @injected_generics, klass: Elements::Generic
      ) + @allowed_generics).uniq{|q| q.name}.select{|l|
        @allowed_generics.map(&:name).include?(l.name) && @injected_generics.keys.include?(l.name)
      }

      generics_expected.each do |generic_expected|
        generic_got = @generic_klass[generic_expected.name]
        expect(generic_got.name).to eq(generic_expected.name)
        expect(generic_got.value).to eq(generic_expected.value)
        expect(generic_got.options).to eq(generic_expected.options)
      end
    end
  end
end

