require 'spec_helper'

RSpec.describe SimpleAMS::Adapters::AMS, 'collection' do
  context 'with various options' do
    before do
      UserSerializer.adapter(SimpleAMS::Adapters::AMS)
      @user_attrs = (Helpers.pick(User.model_attributes, min: 1) + [:id]).uniq
      UserSerializer.attributes(*@user_attrs)
      rand(2..11).times.map { Elements.link }.each do |link|
        UserSerializer.link(*link.as_input)
      end
      rand(2..11).times.map { Elements.meta }.each do |meta|
        UserSerializer.meta(*meta.as_input)
      end
      User.relations.each do |relation|
        UserSerializer.send(relation.type, relation.name, relation.options)
      end

      @micropost_attrs = Helpers.pick(Micropost.model_attributes, min: 1)
      MicropostSerializer.attributes(*@micropost_attrs)
      @address_attrs = Helpers.pick(Address.model_attributes, min: 1)
      AddressSerializer.attributes(*@address_attrs)

      @includes = %i[address microposts followers]
      @collection = rand(10).times.map { User.new }
      @renderer = SimpleAMS::Renderer::Collection.new(@collection, {
        serializer: UserSerializer, includes: @includes
      })

      @array_hash = JSON.parse(@renderer.to_json, symbolize_names: true)
      @folder = @renderer.folder

      @attrs = {
        users: @user_attrs,
        followers: @user_attrs,
        followings: @user_attrs,
        microposts: @micropost_attrs,
        address: @address_attrs
      }
    end

    context 'fields' do
      it 'returns the correct fields' do
        expect(@array_hash.count == @collection.count)
        @array_hash.each do |hash|
          expect(hash.keys.count > 0).to eq true
          expect(
            hash.keys - %i[links metas] - User.relations.map(&:name)
          ).to eq @user_attrs
          expect(hash[:id]).not_to be_nil

          user = @collection.find { |u| u.id == hash[:id] }

          (
            hash.keys - %i[links metas] - User.relations.map(&:name)
          ).each do |key|
            if user.send(key).is_a? Date
              expect(hash[key]).to eq(user.send(key).to_s)
            else
              expect(hash[key]).to eq(user.send(key))
            end
          end
        end
      end
    end

    context 'links and metas' do
      it 'returns the correct links' do
        @array_hash.each do |hash|
          document = @folder.find { |d| d.fields[:id].value == hash[:id] }

          expect(hash[:links].keys.count > 0).to eq true

          expect(hash[:links].keys).to eq document.links.map(&:name)
          hash[:links].each_key do |key|
            expect(hash[:links][key]).to eq(document.links[key].value)
          end
        end
      end

      it 'returns the correct metas' do
        @array_hash.each do |hash|
          document = @folder.find { |d| d.fields[:id].value == hash[:id] }

          expect(hash[:metas].keys.count > 0).to eq true

          expect(hash[:metas].keys).to eq document.metas.map(&:name)
          hash[:metas].each_key do |key|
            expect(hash[:metas][key]).to eq(document.metas[key].value)
          end
        end
      end
    end

    context 'relations' do
      it 'returns the correct relations' do
        @array_hash.each do |hash|
          expect(
            (hash.keys - @user_attrs - %i[links metas]).sort
          ).to eq @includes.sort

          expect(
            @includes.map { |name| hash[name] }.all? do |relation|
              relation.is_a?(Array) || relation.is_a?(Hash)
            end
          ).to eq true

          @includes.map { |name| [name, hash[name]] }.each do |name, relation|
            next if relation.nil? || relation.empty?

            keys = if relation.is_a?(Array)
                     (relation.first&.keys || []) - %i[links metas]
                   else
                     relation.keys - %i[links metas]
                   end
            expect(keys).to eq(@attrs[name] || [])
          end
        end
      end
    end
  end

  context 'with various options and deep nested includes' do
    before do
      UserSerializer.adapter(SimpleAMS::Adapters::AMS)
      @user_attrs = (Helpers.pick(User.model_attributes, min: 1) + [:id]).uniq
      UserSerializer.attributes(*@user_attrs)
      rand(2..11).times.map { Elements.link }.each do |link|
        UserSerializer.link(*link.as_input)
      end
      rand(2..11).times.map { Elements.meta }.each do |meta|
        UserSerializer.meta(*meta.as_input)
      end
      User.relations.each do |relation|
        UserSerializer.send(relation.type, relation.name, relation.options)
      end

      @micropost_attrs = Helpers.pick(Micropost.model_attributes, min: 1)
      MicropostSerializer.attributes(*@micropost_attrs)
      @address_attrs = Helpers.pick(Address.model_attributes, min: 1)
      AddressSerializer.attributes(*@address_attrs)

      @includes = [:address, :microposts, { followers: [:microposts, { followings: [:microposts] }] }]
      @collection = rand(10).times.map { User.new }
      @renderer = SimpleAMS::Renderer::Collection.new(@collection, {
        serializer: UserSerializer, includes: @includes
      })

      @array_hash = JSON.parse(@renderer.to_json, symbolize_names: true)
      @folder = @renderer.folder

      @first_level_includes = %i[address microposts followers]
      @second_level_includes = %i[microposts followings]
      @third_level_includes = [:microposts]

      @attrs = {
        users: @user_attrs,
        followers: @user_attrs,
        followings: @user_attrs,
        microposts: @micropost_attrs,
        address: @address_attrs
      }
    end

    context 'fields' do
      it 'returns the correct fields' do
        expect(@array_hash.count == @collection.count)
        @array_hash.each do |hash|
          expect(hash.keys.count > 0).to eq true
          expect(
            hash.keys - %i[links metas] - User.relations.map(&:name)
          ).to eq @user_attrs
          expect(hash[:id]).not_to be_nil

          user = @collection.find { |u| u.id == hash[:id] }

          (
            hash.keys - %i[links metas] - User.relations.map(&:name)
          ).each do |key|
            if user.send(key).is_a? Date
              expect(hash[key]).to eq(user.send(key).to_s)
            else
              expect(hash[key]).to eq(user.send(key))
            end
          end
        end
      end
    end

    context 'links and metas' do
      it 'returns the correct links' do
        @array_hash.each do |hash|
          document = @folder.find { |d| d.fields[:id].value == hash[:id] }

          expect(hash[:links].keys.count > 0).to eq true

          expect(hash[:links].keys).to eq document.links.map(&:name)
          hash[:links].each_key do |key|
            expect(hash[:links][key]).to eq(document.links[key].value)
          end
        end
      end

      it 'returns the correct metas' do
        @array_hash.each do |hash|
          document = @folder.find { |d| d.fields[:id].value == hash[:id] }

          expect(hash[:metas].keys.count > 0).to eq true

          expect(hash[:metas].keys).to eq document.metas.map(&:name)
          hash[:metas].each_key do |key|
            expect(hash[:metas][key]).to eq(document.metas[key].value)
          end
        end
      end
    end

    context 'relations' do
      it 'returns the correct relations' do
        @array_hash.each do |hash|
          expect(
            (hash.keys - @user_attrs - %i[links metas]).sort
          ).to eq @first_level_includes.sort

          expect(
            @first_level_includes.map { |name| hash[name] }.all? do |relation|
              relation.is_a?(Array) || relation.is_a?(Hash)
            end
          ).to eq true

          @first_level_includes.map { |name| [name, hash[name]] }.each do |name, relation|
            next if relation.nil? || relation.empty?

            keys = if relation.is_a?(Array)
                     (relation.first&.keys || []) - %i[links metas]
                   else
                     relation.keys - %i[links metas]
                   end

            expect(keys - @second_level_includes).to eq(@attrs[name] || [])

            [
              [:microposts, (hash[:followers].first || {})[:microposts]],
              [:followings, (hash[:followers].first || {})[:followings]]
            ].each do |name2, relation2|
              next if relation2.nil? || relation2.empty?

              keys2 = if relation2.is_a?(Array)
                        (relation2.first&.keys || []) - %i[links metas]
                      else
                        relation2.keys - %i[links metas]
                      end

              expect(keys2 - @third_level_includes).to eq(@attrs[name2] || [])
            end
          end
        end
      end
    end
  end
end
