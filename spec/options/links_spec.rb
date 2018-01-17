require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Options, 'links' do
  context "with no links in general" do
    before do
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
        }).tap{|h| h.delete(:links)}
      )
    end

    it "returns empty links array" do
      expect(@options.links).to eq []
    end
  end

  context "with no injected links" do
    before do
      @allowed_links = Elements.links
      @allowed_links.each do |link|
        UserSerializer.link(*link.as_input)
      end

      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer
        }).tap{|h| h.delete(:links)}
      )

      @uniq_allowed_links = @allowed_links.uniq{|l| l.name}
    end

    it "returns the allowed ones" do
      expect(@options.links.map(&:name)).to eq @uniq_allowed_links.map(&:name)
      expect(@options.links.map(&:value)).to eq @uniq_allowed_links.map(&:value)
      expect(@options.links.map(&:options)).to eq @uniq_allowed_links.map(&:options)
    end
  end

  context "with empty injected links" do
    before do
      @allowed_links = Elements.links
      @allowed_links.each do |link|
        UserSerializer.link(*link.as_input)
      end

      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
          links: []
        })
      )
    end

    it "returns empty links array" do
      expect(@options.links).to eq []
    end
  end

  context "with no allowed links but injected ones" do
    before do
      @options = SimpleAMS::Options.new(
        User.new,
        Helpers.random_options_with({
          serializer: UserSerializer,
        })
      )
    end

    it "returns empty links array" do
      expect(@options.links).to eq []
    end
  end

  context "with various injected links" do
    before do
      @allowed_links = Elements.links
      @allowed_links.each do |link|
        UserSerializer.link(*link.as_input)
      end
      @injected_links = Elements.as_options_for(
        @allowed_links.sample(rand(@allowed_links.length) + 1)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        links: @injected_links
      })
      @options = SimpleAMS::Options.new(
        User.new,
        injected_options
      )
    end

    it "holds the uniq union of injected and allowed links" do
      expect(@options.links.map(&:name)).to(
        eq(
          @allowed_links.map(&:name) & Elements.as_elements_for(
            @injected_links, klass: Elements::Link
          ).map(&:name)
        )
      )
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
        @allowed_links.sample(rand(@allowed_links.length) + 1)
      )

      injected_options = Helpers.random_options_with({
        serializer: UserSerializer,
        links: @injected_links
      })
      @options = SimpleAMS::Options.new(
        User.new,
        injected_options
      )
    end

    it "holds the uniq union of injected and allowed links" do
      expect(@options.links.map(&:name)).to(
        eq(
          @allowed_links.map(&:name) & Elements.as_elements_for(
            @injected_links, klass: Elements::Link
          ).map(&:name)
        )
      )
    end
  end
end
