require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Options, 'links' do
  context "with no links in general" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap{|h| h.delete(:links)}
      })
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

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer
        }).tap{|h| h.delete(:links)}
      })

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

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          links: []
        })
      })
    end

    it "returns empty links array" do
      expect(@options.links).to eq []
    end
  end

  context "with no allowed links but injected ones" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        })
      })
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
        Helpers.pick(@allowed_links)
      )

      injected_options = Helpers.random_options(with:{
        serializer: UserSerializer,
        links: @injected_links
      })
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: injected_options
      })
    end

    it "holds the uniq union of injected and allowed links" do
      links_got = @options.links
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

      injected_options = Helpers.random_options(with:{
        serializer: UserSerializer,
        links: @injected_links
      })
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: injected_options
      })
    end

    it "holds the uniq union of injected and allowed links" do
      links_got = @options.links
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

  context "with lambda" do
    context "allowed links" do
      before do
        @user = User.new
        @allowed_links = [
          Elements::Link.new(
            name: :user, value: ->(obj){
              ["api/v1/users/#{@user.id}", {rel: :user}]
            }
          ),
          Elements::Link.new(
            name: :root, value: "api/v1/root", options: {rel: :root}
          ),
        ]
        @allowed_links.each do |link|
          UserSerializer.link(*link.as_input)
        end

        @options = SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }, without: [:links])
        })
      end

      it "holds the unwrapped links" do
        expect(@options.links.count).to eq(2)

        expect(@options.links.first.name).to eq(@allowed_links.first.name)
        expect(@options.links.first.value).to eq(@allowed_links.first.value.call(@user).first)
        expect(@options.links.first.options).to eq(@allowed_links.first.value.call(@user).last)

        expect(@options.links.last.name).to eq(@allowed_links.last.name)
        expect(@options.links.last.value).to eq(@allowed_links.last.value)
        expect(@options.links.last.options).to eq(@allowed_links.last.options)
      end
    end

    context "injected links" do
      before do
        @user = User.new
        @allowed_links = Elements.links
        @allowed_links.each do |link|
          UserSerializer.link(*link.as_input)
        end

        #@injected_links = Helpers.pick(@allowed_links).inject({}) { |memo, link|
        @injected_links = [@allowed_links.first].inject({}) { |memo, link|
          memo[link.name] = ->(obj){ ["/api/v1/#{@user.id}/#{link.name}", rel: link.name] }
          memo
        }

        @options = SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            links: @injected_links
          })
        })
      end

      it "holds the injected lambda links" do
        expect(@options.links.count).to eq(@injected_links.count)

        @options.links.each do |link|
          expect(link.name).to eq(@injected_links.find{|l| l.first == link.name}[0])
          expect(link.value).to eq(@injected_links[link.name].call(@user).first)
        end
      end
    end
  end
end
