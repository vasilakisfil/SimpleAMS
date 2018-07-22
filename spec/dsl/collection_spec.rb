require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'collection' do
  context "with no collection options" do
    it "returns a nil collection value" do
      expect(UserSerializer.collection).to eq nil
    end
  end

  #that's interesting test case, should blog post
  context "with attributes specified" do
    before do
      Helpers.define_singleton_for('RandomOptions', {
        links: (rand(10) + 2).times.map{ Elements.link },
        metas: (rand(10) + 2).times.map{ Elements.meta }
      })
      UserSerializer.collection do
        Helpers::RandomOptions.links.each do |l|
          link(*l.as_input)
        end
        Helpers::RandomOptions.metas.each do |m|
          meta(*m.as_input)
        end
      end
    end

    it "creates the embedded Collection class along with the specified options" do
      expect(UserSerializer::Collection.class).to eq(Class)
      expect(UserSerializer.collection).to eq(UserSerializer::Collection)
      expect(UserSerializer.collection.links).to(
        eq(Helpers::RandomOptions.links.map(&:as_input))
      )
      expect(UserSerializer.collection.metas).to(
        eq(Helpers::RandomOptions.metas.map(&:as_input))
      )
    end
  end
end
