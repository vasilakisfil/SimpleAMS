require "spec_helper"

RSpec.describe SimpleAMS::Document, 'fields' do
  let(:document_expecations) {
    ->(document, overrides, model, allowed = nil) {
      model_attrs = model.class.model_attributes
      model_attrs = allowed if allowed

      document.fields.each_with_index do |field, index|
        expect(field).to respond_to(:key)
        expect(field).to respond_to(:value)
        expect(field.key).to eq(model_attrs[index])

        if overrides.include?(field.key)
          if model.send(model_attrs[index]).respond_to?('*')
            expect(field.value).to eq(model.send(model_attrs[index])*2)
          else
            expect(field.value).to eq('Something else')
          end
        else
          expect(field.value).to eq(model.send(model_attrs[index]))
        end
      end
    }
  }

  context "with no fields in general" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }).tap { |h| h.delete(:fields) }
        })
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.fields.map(&:key)).to eq []
        expect(@document.options.fields).to eq []
        expect(@document.fields.any?).to eq false
        expect(@document.fields.empty?).to eq true
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.fields).to respond_to(:each)
        @document.fields.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  describe "with no injected fields" do
    before do
      @user = User.new

      @overrides = Helpers.initialize_with_overrides(UserSerializer)
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }).tap { |h| h.delete(:fields) }
        })
      )
    end

    after do
      UserSerializer.undefine_all
    end

    context "members" do
      it "holds the allowed fields only" do
        expect(@document.fields.map(&:key)).to eq User.model_attributes
      end
    end

    context "values" do
      it "returns the allowed fields" do
        expect(@document.fields).to respond_to(:each)
        instance_exec(@document, @overrides, @user, &document_expecations)
      end
    end
  end

  context "with empty injected fields" do
    before do
      @user = User.new
      @overrides = Helpers.initialize_with_overrides(UserSerializer)
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            fields: []
          })
        })
      )
    end

    after do
      UserSerializer.undefine_all
    end


    describe "members" do
      it "holds the allowed fields only" do
        expect(@document.fields).to eq []
        expect(@document.options.fields).to eq []
      end
    end

    context "values" do
      it "returns an empty array" do
        expect(@document.fields).to respond_to(:each)
        instance_exec(@document, @overrides, @user, &document_expecations)
      end
    end
  end

  context "with various injected fields" do
    before do
      @user = User.new
      @allowed = Helpers.pick(User.model_attributes)
      @overrides = Helpers.initialize_with_overrides(UserSerializer, allowed: @allowed)
      UserSerializer.attributes(*@allowed)
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            fields: User.model_attributes
          })
        })
      )
    end

    after do
      UserSerializer.undefine_all
    end

    describe "members" do
      it "holds the allowed fields only" do
        expect(@document.fields.map(&:key)).to eq @allowed
      end
    end

    context "values" do
      it "returns an empty array" do
        expect(@document.fields).to respond_to(:each)
        instance_exec(@document, @overrides, @user, @allowed, &document_expecations)
      end
    end
  end

  context "with repeated fields" do
    before do
      @user = User.new
      @allowed = Helpers.pick(User.model_attributes)
      @overrides = Helpers.initialize_with_overrides(UserSerializer, allowed: @allowed)
      UserSerializer.attributes(*(@allowed + @allowed))
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            fields: (User.model_attributes + User.model_attributes)
          })
        })
      )
    end

    after do
      UserSerializer.undefine_all
    end

    describe "members" do
      it "holds the allowed fields only" do
        expect(@document.fields.map(&:key)).to eq @allowed

        expect(@document.fields.any?).to eq @allowed.any?
        expect(@document.fields.empty?).to eq @allowed.empty?
      end
    end

    context "values" do
      it "returns an empty array" do
        expect(@document.fields).to respond_to(:each)
        instance_exec(@document, @overrides, @user, @allowed, &document_expecations)
      end
    end
  end

  context "with overriden fields by methods" do
    skip("this is already tested by #with_overrides method")
  end

  context "accessing a field through Document::Field class" do
    before do
      @user = User.new
      @allowed = User.model_attributes
      @overrides = Helpers.initialize_with_overrides(UserSerializer, allowed: @allowed)
      UserSerializer.attributes(*@allowed)
      @field_klass = SimpleAMS::Document::Fields.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            fields: User.model_attributes
          })
        })
      )
    end

    after do
      UserSerializer.undefine_all
    end

    describe "members" do
      it "holds the allowed fields only" do
        fields = (@allowed - User.relations.map(&:name))

        expect(@field_klass.any?).to eq fields.any?
        expect(@field_klass.empty?).to eq fields.empty?

        fields.each do |field|
          if @overrides.include?(field)
            if @user.send(field).respond_to?('*')
              expect(@field_klass[field].value).to eq(@user.send(field) * 2)
            else
              expect(@field_klass[field].value).to eq('Something else')
            end
          else
            expect(@field_klass[field].value).to eq(@user.send(field))
          end
        end
      end
    end
  end
end
