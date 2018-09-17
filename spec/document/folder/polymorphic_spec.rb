require "spec_helper"

RSpec.describe SimpleAMS::Document::Folder, 'polymorphic collections' do
  describe "without specifying a collection_serializer various options" do
    before do
      @setup_helper = SetupHelper.new
      @setup_helper.set_collection_allowed_options! #probably not needed
      @setup_helper.set_resource_allowed_options!

      @collection = 10.times.map{|i| User.new(id: i)}

    end

    it "raises an error regarding collection serializer" do
      expect{
        SimpleAMS::Document::Folder.new(
          SimpleAMS::Options.new(@collection, {
            injected_options: @setup_helper.injected_options.merge({
              serializer: ->(obj){ obj.id < 5 ? UserSerializer : Api::V1::UserSerializer},
            })
          })
        )
      }.to raise_error(/specify a collection_serializer/i)
    end
  end

  describe "with specifying a collection_serializer and various options" do
    before do
      @setup_helper = SetupHelper.new
      @setup_helper.set_collection_allowed_options! #probably not needed
      @setup_helper.set_resource_allowed_options!

      @collection = 10.times.map{User.new}

      class Api::V1::UserSimpleSerializer < UserSerializer; end;

      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(@collection, {
          injected_options: @setup_helper.injected_options.merge({
            serializer: ->(obj){ obj.id < 5 ? UserSerializer : Api::V1::UserSimpleSerializer},
            collection_serializer: UserSerializer
          })
        })
      )
    end

    it "returns correct documents" do
      expect(@folder.documents.count).to eq @collection.count
      @folder.documents.each do |document|
        expect(document.name).to eq @collection.first.class.to_s.downcase.to_sym

        expect(document.type.name).to eq @collection.first.class.to_s.downcase.to_sym

        expect(document.adapter.name).to eq @setup_helper.injected_options[:adapter].first
        expect(document.adapter.options).to eq @setup_helper.injected_options[:adapter].last

        expect(document.fields.members).to eq @setup_helper.injected_options[:fields]

        expect(document.relations.map(&:name)).to eq @setup_helper.expected_relations_names
        expect(document.relations.count).to eq @setup_helper.expected_relations_count

        expect(document.links.map(&:name)).to eq @setup_helper.injected_options[:links].map(&:first).uniq
        expect(document.links.map(&:value)).to eq @setup_helper.injected_options[:links].uniq(&:first).map{|l| l[1]}
        expect(document.links.map(&:options)).to eq @setup_helper.injected_options[:links].uniq(&:first).map(&:last)

        expect(document.metas.map(&:name)).to eq @setup_helper.injected_options[:metas].map(&:first).uniq
        expect(document.metas.map(&:value)).to eq @setup_helper.injected_options[:metas].uniq(&:first).map{|l| l[1]}
        expect(document.metas.map(&:options)).to eq @setup_helper.injected_options[:metas].uniq(&:first).map(&:last)

        if document.resource.id < 5
          expect(document.serializer.class).to eq UserSerializer
        else
          expect(document.serializer.class).to eq Api::V1::UserSimpleSerializer
        end

      end
    end
  end
end
