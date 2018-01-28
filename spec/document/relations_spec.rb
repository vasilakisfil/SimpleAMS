require "spec_helper"

#these tests have real relations compared to options/dsl that have random inputs
#TODO: Add tests for injected relationships
RSpec.describe SimpleAMS::Document, "relations" do
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

  context "with no reations in general" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
          }).tap{|h|
            h.delete(:includes)
            h.delete(:relations)
          }
        )
      )
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.relations).to respond_to(:each)
        @document.relations.each do |field|
          fail('this should never happen as relations should be empty')
        end
      end
    end
  end

  context "with no injected includes" do
    before do
      @user = User.new
      @allowed_relations = User.relations
      @allowed_relations.each do |relation|
        UserSerializer.send(relation.type, relation.name, options: relation.options)
      end
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: @user,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
          }).tap{|h| h.delete(:includes)}
        )
      )
    end

    context "values" do
      it "returns the allowed relations" do
        expect(@document.relations).to respond_to(:each)
        expect(@document.relations.map(&:name)).to(
          eq(
            @allowed_relations.map(&:name)
          )
        )
        @document.relations.each_with_index do |relation, index|
          expect(relation.name).to eq(@allowed_relations[index].name)
          expect(relation.document.name).to eq(@allowed_relations[index].name)
        end
      end
    end
  end

  context "with empty injected includes" do
    before do
      @user = User.new
      @allowed_relations = User.relations
      @allowed_relations.each do |relation|
        UserSerializer.send(relation.type, relation.name, options: relation.options)
      end
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: @user,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
            includes: []
          })
        )
      )
    end

    context "values" do
      it "returns an empty array" do
        expect(@document.relations).to respond_to(:each)
        expect(@document.relations.map(&:name)).to eq([])
        @document.relations.each do |field|
          fail('this should never happen as relations should be empty')
        end
      end
    end
  end

  context "with no allowed relations but injected ones" do
    pending('Needs implementation')
  end

  context "with various includes" do
    before do
      @allowed_relations = User.relations
      @allowed_relations.each do |relation|
        UserSerializer.send(relation.type, relation.name, options: relation.options)
      end
      @injected_relations = Helpers.pick(@allowed_relations)
      @user = User.new
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: @user,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
            includes: @injected_relations
          })
        )
      )
    end

    context "values" do
      it "returns the specified relations" do
        expect(@document.relations).to respond_to(:each)
        expect(@document.relations.map(&:name)).to eq([])
        @document.relations.each do |field|
          fail('this should never happen as relations should be empty')
        end
      end
    end
  end

  context "with repeated includes" do
    before do
      @allowed_relations = User.relations
      2.times{
        @allowed_relations.each do |relation|
          UserSerializer.send(relation.type, relation.name, options: relation.options)
        end
      }
      @injected_relations = Helpers.pick(@allowed_relations)
      @user = User.new
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: @user,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
            includes: @injected_relations
          })
        )
      )
    end

    context "values" do
      it "returns the specified relations" do
        expect(@document.relations).to respond_to(:each)
        expect(@document.relations.map(&:name)).to eq([])
        @document.relations.each do |field|
          fail('this should never happen as relations should be empty')
        end
      end
    end
  end
end
