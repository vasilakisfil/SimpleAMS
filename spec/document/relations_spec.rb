require "spec_helper"

#these tests have real relations compared to options/dsl that have random inputs
#TODO: Add tests for injected relations
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
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
          }).tap{|h|
            h.delete(:includes)
            h.delete(:relations)
          }
        })
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
        UserSerializer.send(relation.type, relation.name, relation.options)
      end
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
          }).tap{|h| h.delete(:includes)}
        })
      )
    end

    context "values" do
      it "returns the allowed relations" do
          expect(@document.relations.available).to respond_to(:each)
          expect(@document.relations.available.map(&:name)).to(
            eq(
              @allowed_relations.map(&:name)
            )
          )
          @document.relations.available.each_with_index do |relation, index|
            if relation.folder? && relation.documents.first
              expect(relation.documents.first.name).to eq(
                @allowed_relations[index].options[:serializer].to_s.gsub('Serializer','').downcase.to_sym
              )
            else
              expect(relation.name).to eq(@allowed_relations[index].name)
            end
          end
      end
    end
  end

  context "with empty injected includes" do
    before do
      @user = User.new
      @allowed_relations = User.relations
      @allowed_relations.each do |relation|
        UserSerializer.send(relation.type, relation.name, relation.options)
      end
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            includes: []
          })
        })
      )
    end

    context "values" do
      it "returns an empty array" do
        expect(@document.relations.available).to respond_to(:each)
        expect(@document.relations.available.map(&:name)).to eq([])
        @document.relations.available.each do |field|
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
        UserSerializer.send(relation.type, relation.name, relation.options)
      end
      @injected_relations = Helpers.pick(@allowed_relations)
      @user = User.new
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            includes: @injected_relations
          })
        })
      )
    end

    context "values" do
      it "returns the specified relations" do
        expect(@document.relations.available).to respond_to(:each)
        expect(@document.relations.available.map(&:name)).to eq([])
        @document.relations.available.each do |field|
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
          UserSerializer.send(relation.type, relation.name, relation.options)
        end
      }
      @injected_relations = Helpers.pick(@allowed_relations)
      @user = User.new
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            includes: @injected_relations
          })
        })
      )
    end

    context "values" do
      it "returns the specified relations" do
        expect(@document.relations.available).to respond_to(:each)
        expect(@document.relations.available.map(&:name)).to eq([])
        @document.relations.available.each do |field|
          fail('this should never happen as relations should be empty')
        end
      end
    end
  end

  context "with overriden relation values" do
    before do
      @user = User.new
      @allowed_relations = User.relations
      @allowed_relations.each do |relation|
        UserSerializer.send(
          relation.type,
          relation.name,
          relation.options
        )
      end
      @allowed_relations.each do |relation|
        UserSerializer.send(:define_method, relation.name) do
          name = relation.options[:serializer].to_s.gsub('Serializer', '')
          #TODO: Can you add test error handler here in case you override and return a non-array?
          if relation.type == :has_many
            [Object.const_get("#{name.capitalize}::Sub#{name.capitalize}").new]
          else
            Object.const_get("#{name.capitalize}::Sub#{name.capitalize}").new
          end
        end
      end
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
          }).tap{|h| h.delete(:includes)}
        })
      )
    end

    after do
      @allowed_relations.each do |relation|
        UserSerializer.send(:undef_method, relation.name)
      end
    end

    context "values" do
      it "returns the allowed relations" do
        expect(@document.relations.available).to respond_to(:each)
        expect(@document.relations.available.map(&:name)).to(
          eq(
            @allowed_relations.map(&:name)
          )
        )
        @document.relations.available.each_with_index do |relation, index|
          if relation.folder?
            expect(relation.documents.first.name).to eq(
              @allowed_relations[index].options[:serializer].to_s.gsub('Serializer','').downcase.to_sym
            )
            expect(relation.documents.first.send(:resource).class).to(
               eq(relation.send(:options).resource.first.class)
            )
          else
            expect(relation.send(:resource).class).to(
              eq(relation.send(:options).resource.class)
            )
            expect(relation.name).to eq(@allowed_relations[index].name)
          end
        end

        @allowed_relations.each do |relation|
          if relation.type == :has_many
            expect(@document.relations.available[relation.name].documents.first.name).to(
              eq(relation.options[:serializer].to_s.gsub('Serializer','').downcase.to_sym)
            )
            expect(@document.relations.available[relation.name].documents.first.send(:resource).class).to(
              eq(@document.relations.available[relation.name].send(:options).resource.first.class)
            )
          else
            expect(@document.relations.available[relation.name].name).to eq(relation.name)
            expect(@document.relations.available[relation.name].send(:resource).class).to(
              eq(@document.relations.available[relation.name].send(:options).resource.class)
            )
          end
        end
      end
    end
  end

  context "with namespaced serializer" do
    before do
      @user = User.new
      @allowed_relations = User.relations
      @allowed_relations.each do |relation|
        Api::V1::UserSerializer.send(relation.type, relation.name)
      end
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: Api::V1::UserSerializer,
          }).tap{|h| h.delete(:includes)}
        })
      )
    end

    context "values" do
      it "returns the allowed relations" do
        expect(@document.relations.available).to respond_to(:each)
        expect(@document.relations.available.map(&:name)).to(
          eq(
            @allowed_relations.map(&:name)
          )
        )
        @document.relations.available.each_with_index do |relation, index|
          if relation.folder? && relation.documents.first
            expect(relation.documents.first.name).to eq(
              @allowed_relations[index].options[:serializer].to_s.gsub('Serializer','').downcase.to_sym
            )
          else
            expect(relation.name).to eq(@allowed_relations[index].name)
          end
        end
      end
    end
  end

  context "with namespaced serializer that can't be found" do
    before do
      @user = User.new
      @allowed_relations = User.relations
      @allowed_relations.each do |relation|
        Api::V1::UserSerializer.send(relation.type, relation.name)
      end
      Api::V1::UserSerializer.has_one :id #obviously it doesn't make any sense
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: Api::V1::UserSerializer,
          }).tap{|h| h.delete(:includes)}
        })
      )
    end

    context "values" do
      it "returns the allowed relations" do
          expect(@document.relations.available).to respond_to(:each)
          expect{@document.relations.available.map(&:name)}.to raise_error(
            RuntimeError, /Could not infer serializer/
          )
      end
    end
  end
end
