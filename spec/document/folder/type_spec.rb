require 'spec_helper'

RSpec.describe SimpleAMS::Document::Folder, 'type' do
  context 'without specifying type' do
    before do
      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(
          10.times.map { User.new },
          injected_options: { serializer: UserSerializer }
        )
      )
    end

    it 'returns default type for collection' do
      expect(@folder.type.value).to eq :user_collection
      expect(@folder.name).to eq :user_collection
    end
  end

  context 'when specifying type in allowed options' do
    before do
      UserSerializer.collection(:users)
      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(
          10.times.map { User.new },
          injected_options: { serializer: UserSerializer }
        )
      )
    end

    it 'returns default type for collection' do
      expect(@folder.type.value).to eq :users
      expect(@folder.name).to eq :users
    end
  end

  context 'when specifying type in allowed options with block' do
    before do
      Helpers.define_singleton_for('RandomOptions', {
        links: rand(2..11).times.map { Elements.link },
        metas: rand(2..11).times.map { Elements.meta }
      })
      UserSerializer.collection(:users) do
        Helpers::RandomOptions.links.each do |l|
          link(*l.as_input)
        end
        Helpers::RandomOptions.metas.each do |m|
          meta(*m.as_input)
        end
      end
      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(
          10.times.map { User.new },
          injected_options: { serializer: UserSerializer }
        )
      )
    end

    it 'returns default type for collection' do
      expect(@folder.type.value).to eq :users
      expect(@folder.name).to eq :users
    end
  end

  context 'when specifying type in injected options' do
    before do
      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(
          10.times.map { User.new },
          injected_options: {
            serializer: UserSerializer, collection: {
              type: :users
            }
          }
        )
      )
    end

    it 'returns default type for collection' do
      expect(@folder.type.value).to eq :users
      expect(@folder.name).to eq :users
    end
  end

  context 'when specifying type in injected options and allowed options' do
    before do
      UserSerializer.collection(:users)
      @folder = SimpleAMS::Document::Folder.new(
        SimpleAMS::Options.new(
          10.times.map { User.new },
          injected_options: {
            serializer: UserSerializer, collection: {
              type: :followers
            }
          }
        )
      )
    end

    it 'returns default type for collection' do
      expect(@folder.type.value).to eq :followers
      expect(@folder.name).to eq :followers
    end
  end
end
