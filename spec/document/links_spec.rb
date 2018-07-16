require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Document, 'links' do
  context "with no links in general" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
          }).tap{|h| h.delete(:links)}
        )
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.links.members).to eq []
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.links).to respond_to(:each)
        @document.links.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with no injected links" do
    before do
      @allowed_links = Elements.links
      @allowed_links.each do |link|
        UserSerializer.link(*link.as_input)
      end

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer
          }).tap{|h| h.delete(:links)}
        )
      )

      @uniq_allowed_links = @allowed_links.uniq{|l| l.name}
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.links.members).not_to eq []
      end
    end

    it "returns the allowed ones" do
      expect(@document.links.map(&:name)).to eq @uniq_allowed_links.map(&:name)
      expect(@document.links.map(&:value)).to eq @uniq_allowed_links.map(&:value)
      expect(@document.links.map(&:options)).to eq @uniq_allowed_links.map(&:options)
    end
  end

  context "with empty injected links" do
    before do
      @allowed_links = Elements.links
      @allowed_links.each do |link|
        UserSerializer.link(*link.as_input)
      end

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
            links: []
          })
        )
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.links.members).to eq []
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.links).to respond_to(:each)
        @document.links.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with no allowed links but injected ones" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: Helpers.random_options_with({
            serializer: UserSerializer,
          })
        )
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.links.members).to eq []
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.links).to respond_to(:each)
        @document.links.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with various injected links" do
    before do
      @allowed_links = Elements.links
      @allowed_links.each do |link|
        UserSerializer.link(*link.as_input)
      end
      @injected_links = Elements.as_options_for(
        Helpers.pick(@allowed_links)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        links: @injected_links
      })
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: injected_options
        )
      )
    end

    it "holds the uniq union of injected and allowed links" do
      links_got = @document.links
      links_expected = (Elements.as_elements_for(
        @injected_links, klass: Elements::Link
      ) + @allowed_links).uniq{|q| q.name}.select{|l|
        @allowed_links.map(&:name).include?(l.name) && @injected_links.keys.include?(l.name)
      }

      expect(links_got.map(&:name)).to eq(links_expected.map(&:name))
      expect(links_got.map(&:value)).to eq(links_expected.map(&:value))
      expect(links_got.map(&:options).count).to eq(links_expected.map(&:options).count)
      expect(links_got.map(&:options)).to eq(links_expected.map(&:options))
    end
  end

  context "with repeated (allowed) links" do
    before do
      @allowed_links = Elements.links
      2.times{
        @allowed_links.each do |link|
          UserSerializer.link(*link.as_input)
        end
      }
      @injected_links = Elements.as_options_for(
        Helpers.pick(@allowed_links)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        links: @injected_links
      })
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(
          resource: User.new,
          injected_options: injected_options
        )
      )
    end

    it "holds the uniq union of injected and allowed links" do
      links_got = @document.links
      _injected_links = Elements.as_elements_for(
        @injected_links, klass: Elements::Link
      )

      links_expected = (_injected_links.map(&:name) & @allowed_links.map(&:name)).map{|name|
        _injected_links.find{|l| l.name == name}
      }

      expect(links_got.map(&:name)).to eq(links_expected.map(&:name))
      expect(links_got.map(&:value)).to eq(links_expected.map(&:value))
      expect(links_got.map(&:options)).to eq(links_expected.map(&:options))
    end
  end

end
