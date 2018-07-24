require "spec_helper"

RSpec.describe SimpleAMS::Options, 'fields' do
  context "with no fields in general" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer
        }).tap{|h| h.delete(:fields)}
      })
    end

    it "returns an empty array" do
      expect(@options.fields).to eq []
    end
  end

  context "with no injected fields" do
    before do
      @allowed_fields = Helpers::Options.array
      UserSerializer.attributes(*@allowed_fields)
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer
        }).tap{|h| h.delete(:fields)}
      })
    end

    it "holds the allowed fields only" do
      expect(@options.fields).to eq @allowed_fields.uniq
    end
  end

  context "with empty injected fields" do
    before do
      @allowed_fields = Helpers::Options.array
      UserSerializer.attributes(*@allowed_fields)
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with: {
          serializer: UserSerializer,
          fields: []
        })
      })
    end

    it "returns an empty array" do
      expect(@options.fields).to eq []
    end
  end

  context "with various injected fields" do
    before do
      @allowed_fields = Helpers::Options.array
      UserSerializer.attributes(*@allowed_fields)
      @injected_options = Helpers.random_options(with: {
        serializer: UserSerializer
      })
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: @injected_options,
      })
    end

    it "holds the union of injected and allowed fields" do
      expect(@options.fields).to(
        eq(
          (UserSerializer.attributes & @injected_options[:fields]).uniq
        )
      )
    end
  end

  context "with repeated fields" do
    before do
      @allowed_fields = Helpers::Options.array
      UserSerializer.attributes(*(@allowed_fields.concat(@allowed_fields)))
      injected_fields = Helpers::Options.array
      @injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        fields: injected_fields.concat(injected_fields)
      })
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: @injected_options,
      })
    end

    it "holds the uniq union of injected and allowed fields" do
      expect(@options.fields).to(
        eq(
          (@allowed_fields & @injected_options[:fields]).uniq
        )
      )
    end
  end
end
