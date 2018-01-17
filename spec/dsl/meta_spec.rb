require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'meta' do
  context "with no metas" do
    it "returns an empty array" do
      expect(UserSerializer.metas).to eq []
    end
  end

  context "with one meta" do
    before do
      @meta = Elements.meta
      UserSerializer.meta(*@meta.as_input)
    end

    it "holds the specified meta" do
      expect(UserSerializer.metas.count).to eq 1
      expect(UserSerializer.metas.first.name).to eq @meta.name
      expect(UserSerializer.metas.first.value).to eq @meta.value
      expect(UserSerializer.metas.first.options).to eq @meta.options
    end
  end

  context "with multiple meta" do
    before do
      @meta = (rand(10) + 2).times.map{ Elements.meta }
      @meta.each{|meta|
        UserSerializer.meta(*meta.as_input)
      }
    end

    it "holds the specified metas" do
      expect(UserSerializer.metas.count).to eq @meta.count
      UserSerializer.metas.each_with_index do |meta, index|
        expect(meta.name).to eq @meta[index].name
        expect(meta.value).to eq @meta[index].value
        expect(meta.options).to eq @meta[index].options
      end
    end
  end
end
