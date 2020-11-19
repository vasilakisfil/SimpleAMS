require 'spec_helper'

RSpec.describe SimpleAMS::Adapters::AMS, 'resource' do
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
      rand(2..11).times.map { Elements.form }.each do |form|
        UserSerializer.form(*form.as_input)
      end
      User.relations.each do |relation|
        UserSerializer.send(relation.type, relation.name, relation.options)
      end

      @micropost_attrs = Helpers.pick(Micropost.model_attributes, min: 1)
      MicropostSerializer.attributes(*@micropost_attrs)
      @address_attrs = Helpers.pick(Address.model_attributes, min: 1)
      AddressSerializer.attributes(*@address_attrs)

      @includes = %i[address microposts followers]
      @user = User.new
      @renderer = SimpleAMS::Renderer.new(@user, {
        serializer: UserSerializer, includes: @includes
      })

      @hash = JSON.parse(@renderer.to_json, symbolize_names: true)
      @document = @renderer.document

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
        expect(@hash.keys.count > 0).to eq true
        expect(
          @hash.keys - %i[links metas forms] - User.relations.map(&:name)
        ).to eq @user_attrs
        expect(@hash[:id]).not_to be_nil

        (
          @hash.keys - %i[links metas forms] - User.relations.map(&:name)
        ).each do |key|
          if @user.send(key).is_a? Date
            expect(@hash[key]).to eq(@user.send(key).to_s)
          else
            expect(@hash[key]).to eq(@user.send(key))
          end
        end
      end
    end

    context 'links, metas and forms' do
      it 'returns the correct links' do
        expect(@hash[:links].keys.count > 0).to eq true

        expect(@hash[:links].keys).to eq @document.links.map(&:name)
        @hash[:links].each_key do |key|
          expect(@hash[:links][key]).to eq(@document.links[key].value)
        end
      end

      it 'returns the correct metas' do
        expect(@hash[:metas].keys.count > 0).to eq true

        expect(@hash[:metas].keys).to eq @document.metas.map(&:name)
        @hash[:metas].each_key do |key|
          expect(@hash[:metas][key]).to eq(@document.metas[key].value)
        end
      end

      it 'returns the correct forms' do
        expect(@hash[:forms].keys.count > 0).to eq true

        expect(@hash[:forms].keys).to eq @document.forms.map(&:name)
        @hash[:forms].each_key do |key|
          expect(@hash[:forms][key]).to eq(@document.forms[key].value)
        end
      end
    end

    context 'relations' do
      it 'returns the correct relations' do
        expect(
          (@hash.keys - @user_attrs - %i[links metas forms]).sort
        ).to eq @includes.sort

        expect(
          @includes.map { |name| @hash[name] }.all? do |relation|
            relation.is_a?(Array) || relation.is_a?(Hash)
          end
        ).to eq true

        @includes.map { |name| [name, @hash[name]] }.each do |name, relation|
          next if relation.nil? || relation.empty?

          keys = if relation.is_a?(Array)
                   (relation.first&.keys || []) - %i[links metas forms]
                 else
                   relation.keys - %i[links metas forms]
                 end

          expect(keys).to eq(@attrs[name] || [])
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
      rand(2..11).times.map { Elements.form }.each do |form|
        UserSerializer.form(*form.as_input)
      end
      User.relations.each do |relation|
        UserSerializer.send(relation.type, relation.name, relation.options)
      end

      @micropost_attrs = Helpers.pick(Micropost.model_attributes, min: 1)
      MicropostSerializer.attributes(*@micropost_attrs)
      @address_attrs = Helpers.pick(Address.model_attributes, min: 1)
      AddressSerializer.attributes(*@address_attrs)

      @includes = [:address, :microposts, { followers: [:microposts, { followings: [:microposts] }] }]
      @user = User.new
      @renderer = SimpleAMS::Renderer.new(@user, {
        serializer: UserSerializer, includes: @includes
      })

      @hash = JSON.parse(@renderer.to_json, symbolize_names: true)
      @document = @renderer.document

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
        expect(@hash.keys.count > 0).to eq true
        expect(
          @hash.keys - %i[links metas forms] - User.relations.map(&:name)
        ).to eq @user_attrs
        expect(@hash[:id]).not_to be_nil

        (
          @hash.keys - %i[links metas forms] - User.relations.map(&:name)
        ).each do |key|
          if @user.send(key).is_a? Date
            expect(@hash[key]).to eq(@user.send(key).to_s)
          else
            expect(@hash[key]).to eq(@user.send(key))
          end
        end
      end
    end

    context 'links, metas and forms' do
      it 'returns the correct links' do
        expect(@hash[:links].keys.count > 0).to eq true

        expect(@hash[:links].keys).to eq @document.links.map(&:name)
        @hash[:links].each_key do |key|
          expect(@hash[:links][key]).to eq(@document.links[key].value)
        end
      end

      it 'returns the correct metas' do
        expect(@hash[:metas].keys.count > 0).to eq true

        expect(@hash[:metas].keys).to eq @document.metas.map(&:name)
        @hash[:metas].each_key do |key|
          expect(@hash[:metas][key]).to eq(@document.metas[key].value)
        end
      end

      it 'returns the correct forms' do
        expect(@hash[:forms].keys.count > 0).to eq true

        expect(@hash[:forms].keys).to eq @document.forms.map(&:name)
        @hash[:forms].each_key do |key|
          expect(@hash[:forms][key]).to eq(@document.forms[key].value)
        end
      end
    end

    context 'relations' do
      it 'returns the correct relations' do
        expect(
          (@hash.keys - @user_attrs - %i[links metas forms]).sort
        ).to eq @first_level_includes.sort

        expect(
          @first_level_includes.map { |name| @hash[name] }.all? do |relation|
            relation.is_a?(Array) || relation.is_a?(Hash)
          end
        ).to eq true

        @first_level_includes.map { |name| [name, @hash[name]] }.each do |name, relation|
          next if relation.nil? || relation.empty?

          keys = if relation.is_a?(Array)
                   (relation.first&.keys || []) - %i[links metas forms]
                 else
                   relation.keys - %i[links metas forms]
                 end

          expect(keys - @second_level_includes).to eq(@attrs[name] || [])

          [
            [:microposts, (@hash[:followers].first || {})[:microposts]],
            [:followings, (@hash[:followers].first || {})[:followings]]
          ].each do |name2, relation2|
            next if relation2.nil? || relation2.empty?

            keys2 = if relation2.is_a?(Array)
                      (relation2.first&.keys || []) - %i[links metas forms]
                    else
                      relation2.keys - %i[links metas forms]
                    end

            expect(keys2 - @third_level_includes).to eq(@attrs[name2] || [])
          end
        end
      end
    end
  end
end
