require "spec_helper"

#fields, links, metas etc are tested by document tests
RSpec.describe SimpleAMS::Document::Folder, 'options' do
  describe "with no injected/allowed collection options" do
    before do
      @injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
      }, without: [:collection])

      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(10.times.map { User.new }, {
          injected_options: @injected_options,
        })
      )
    end

    it "is a folder" do
      expect(@folder.folder?).to eq true
      expect(@folder.document?).to eq false
    end

    it "returns correct collection attributes" do
      expect(@folder.fields).to eq([])
      expect(@folder.links).to eq({})
      expect(@folder.metas).to eq({})
      expect(@folder.relations.count).to eq 0
      #expect(@folder.type.name).to eq :users
    end

    it "returns correct resource attributes" do
      expect(@folder.resource_options.fields).to eq []
      expect(@folder.resource_options.links).to eq []
      expect(@folder.resource_options.metas).to eq []
      expect(@folder.resource_options.relations.count).to eq 0
      #expect(@folder.type.name).to eq :users
    end
  end

  describe "with various allowed collection options" do
    before do
      Helpers.define_singleton_for('RandomOptions', {
        allowed_fields: Elements.fields,
        allowed_links: Elements.links,
        allowed_metas: Elements.metas
      })
      UserSerializer.collection do
        Helpers::RandomOptions.allowed_fields.each do |field|
          attribute(*field.as_input)
        end

        Helpers::RandomOptions.allowed_links.each do |link|
          link(*link.as_input)
        end

        Helpers::RandomOptions.allowed_metas.each do |meta|
          meta(*meta.as_input)
        end
      end

      @injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
      }, without: [:collection])

      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(10.times.map { User.new }, {
          injected_options: @injected_options
        })
      )
    end

    it "returns correct collection attributes" do
      members = @folder.fields.any?? @folder.fields.send(:members) : []
      expect(members).to(
        eq(Helpers::RandomOptions.allowed_fields.map(&:as_input).uniq)
      )
      expect(@folder.links.map(&:name)).to(
        eq(Helpers::RandomOptions.allowed_links.map(&:name).uniq)
      )
      expect(@folder.metas.map(&:name)).to(
        eq(Helpers::RandomOptions.allowed_metas.map(&:name).uniq)
      )
      expect(@folder.relations.count).to eq 0
      #expect(@folder.type.name).to eq :users
    end

    it "returns correct resource attributes" do
      expect(@folder.resource_options.fields).to eq []
      expect(@folder.resource_options.links).to eq []
      expect(@folder.resource_options.metas).to eq []
      expect(@folder.resource_options.relations.count).to eq 0
      #expect(@folder.type.name).to eq :users
    end
  end

  describe "with various injected collection options" do
    before do
      @injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        collection: Helpers.random_options
      })

      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(10.times.map { User.new }, {
          injected_options: @injected_options
        })
      )
    end

    it "returns correct collection attributes" do
      expect(@folder.fields).to eq []
      expect(@folder.links).to eq({})
      expect(@folder.metas).to eq({})
      expect(@folder.relations.count).to eq 0
      #expect(@folder.type.name).to eq :users
    end

    it "returns correct resource attributes" do
      expect(@folder.resource_options.fields).to eq []
      expect(@folder.resource_options.links).to eq []
      expect(@folder.resource_options.metas).to eq []
      expect(@folder.resource_options.relations.count).to eq 0
      #expect(@folder.type.name).to eq :users
    end
  end

  describe "with various allowed collection options" do
    before do
      @setup_helper = SetupHelper.new
      @setup_helper.set_collection_allowed_options!

      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(10.times.map { User.new }, {
          injected_options: @setup_helper.injected_options
        })
      )

    end

    it "returns correct attributes" do
      members = @folder.fields.any?? @folder.fields.send(:members) : []
      expect(members).to(
        eq(@setup_helper.collection_injected.fields.uniq)
      )
      expect(@folder.links.map(&:name)).to(
        eq(@setup_helper.collection_injected.links.map(&:first).uniq)
      )
      expect(@folder.metas.map(&:name)).to(
        eq(@setup_helper.collection_injected.metas.map(&:first).uniq)
      )
      expect(@folder.relations.count).to eq 0
      #expect(@folder.type.name).to eq :users
    end
  end

  describe "with various options for both collection/resource" do
    before do
      @setup_helper = SetupHelper.new
      @setup_helper.set_collection_allowed_options!
      @setup_helper.set_resource_allowed_options!

      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(10.times.map { User.new }, {
          injected_options: @setup_helper.injected_options
        })
      )

    end

    it "returns correct attributes" do
      members = @folder.fields.any?? @folder.fields.send(:members) : []
      expect(members).to(
        eq(@setup_helper.collection_injected.fields.uniq)
      )
      expect(@folder.links.map(&:name)).to(
        eq(@setup_helper.collection_injected.links.map(&:first).uniq)
      )
      expect(@folder.metas.map(&:name)).to(
        eq(@setup_helper.collection_injected.metas.map(&:first).uniq)
      )
      expect(@folder.relations.count).to eq 0
      #expect(@folder.type.name).to eq :users
    end

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
      expect(@folder.resource_options.relations.available.count).to(
        eq(@setup_helper.expected_relations_count)
      )
      #expect(@folder.type.name).to eq :users
    end
  end
end
