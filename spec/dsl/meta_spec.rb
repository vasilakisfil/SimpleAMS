require "spec_helper"

RSpec.describe SimpleAMS::DSL do
  describe "meta" do
    context "with one meta" do
      before do
        @meta = Elements.meta
        User.meta(*@meta.as_input)
      end

      it "holds the specified options" do
        expect(User.meta.count).to eq 1
        expect(User.meta.first.keys.first).to eq @meta.name
        expect(User.meta.first.values.first.first).to eq @meta.value
        expect(User.meta.first.values.first.last).to eq @meta.options
      end
    end

    context "with multiple meta" do
      before do
        @meta = (rand(10) + 2).times.map{ Elements.meta }
        @meta.each{|meta|
          User.meta(*meta.as_input)
        }
      end

      it "holds the specified options" do
        expect(User.meta.count).to eq @meta.count
        User.meta.each_with_index do |meta, index|
          expect(meta.keys.first).to eq @meta[index].name
          expect(meta.values.first.first).to eq @meta[index].value
          expect(meta.values.first.last).to eq @meta[index].options
        end
      end
    end
  end
end

