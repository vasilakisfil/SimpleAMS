require "spec_helper"

RSpec.describe SimpleAMS::Document::Folder do
  describe "with various options for both collection/resource" do
    before do
      @setup_helper = SetupHelper.new
      @setup_helper.set_collection_allowed_options! #probably not needed
      @setup_helper.set_resource_allowed_options!

      @collection = 10.times.map{User.new}

      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(@collection, {
          injected_options: @setup_helper.injected_options
        })
      )

    end

    it "returns correct documents" do
      expect(@folder.documents.count).to eq @collection.count
    end
=begin
    it "returns correct resource attributes" do
      expect(@folder.resource_options.fields).to(
        eq(@setup_helper.resource_injected.fields.uniq)
      )
      expect(@folder.resource_options.links.map(&:name)).to(
        eq(@setup_helper.resource_injected.links.map(&:name).uniq)
      )
      expect(@folder.resource_options.metas.map(&:name)).to(
        eq(@setup_helper.resource_injected.metas.map(&:name).uniq)
      )
      expect(@folder.resource_options.relations.count).to(
        eq(@setup_helper.expected_relations_count)
      )
      #expect(@folder.type.name).to eq :users
    end
=end
  end
end
