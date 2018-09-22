require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Options, 'forms' do
  context "with no forms in general" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        }).tap{|h| h.delete(:forms)}
      })
    end

    it "returns empty forms array" do
      expect(@options.forms).to eq []
    end
  end

  context "with no injected forms" do
    before do
      @allowed_forms = Elements.forms
      @allowed_forms.each do |form|
        UserSerializer.form(*form.as_input)
      end

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer
        }).tap{|h| h.delete(:forms)}
      })

      @uniq_allowed_forms = @allowed_forms.uniq{|l| l.name}
    end

    it "returns the allowed ones" do
      expect(@options.forms.map(&:name)).to eq @uniq_allowed_forms.map(&:name)
      expect(@options.forms.map(&:value)).to eq @uniq_allowed_forms.map(&:value)
      expect(@options.forms.map(&:options)).to eq @uniq_allowed_forms.map(&:options)
    end
  end

  context "with empty injected forms" do
    before do
      @allowed_forms = Elements.forms
      @allowed_forms.each do |form|
        UserSerializer.form(*form.as_input)
      end

      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
          forms: []
        })
      })
    end

    it "returns empty forms array" do
      expect(@options.forms).to eq []
    end
  end

  context "with no allowed forms but injected ones" do
    before do
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: Helpers.random_options(with:{
          serializer: UserSerializer,
        })
      })
    end

    it "returns empty forms array" do
      expect(@options.forms).to eq []
    end
  end

  context "with various injected forms" do
    before do
      @allowed_forms = Elements.forms
      @allowed_forms.each do |form|
        UserSerializer.form(*form.as_input)
      end
      @injected_forms = Elements.as_options_for(
        Helpers.pick(@allowed_forms)
      )

      injected_options = Helpers.random_options(with:{
        serializer: UserSerializer,
        forms: @injected_forms
      })
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: injected_options
      })
    end

    it "holds the uniq union of injected and allowed forms" do
      forms_got = @options.forms
      _injected_forms = Elements.as_elements_for(
        @injected_forms, klass: Elements::Form
      )

      forms_expected = (_injected_forms.map(&:name) & @allowed_forms.map(&:name)).map{|name|
        _injected_forms.find{|l| l.name == name}
      }

      expect(forms_got.map(&:name)).to eq(forms_expected.map(&:name))
      expect(forms_got.map(&:value)).to eq(forms_expected.map(&:value))
      expect(forms_got.map(&:options)).to eq(forms_expected.map(&:options))
    end
  end

  context "with repeated (allowed) forms" do
    before do
      @allowed_forms = Elements.forms
      2.times{
        @allowed_forms.each do |form|
          UserSerializer.form(*form.as_input)
        end
      }
      @injected_forms = Elements.as_options_for(
        Helpers.pick(@allowed_forms)
      )

      injected_options = Helpers.random_options(with:{
        serializer: UserSerializer,
        forms: @injected_forms
      })
      @options = SimpleAMS::Options.new(User.new, {
        injected_options: injected_options
      })
    end

    it "holds the uniq union of injected and allowed forms" do
      forms_got = @options.forms
      _injected_forms = Elements.as_elements_for(
        @injected_forms, klass: Elements::Form
      )

      forms_expected = (_injected_forms.map(&:name) & @allowed_forms.map(&:name)).map{|name|
        _injected_forms.find{|l| l.name == name}
      }

      expect(forms_got.map(&:name)).to eq(forms_expected.map(&:name))
      expect(forms_got.map(&:value)).to eq(forms_expected.map(&:value))
      expect(forms_got.map(&:options)).to eq(forms_expected.map(&:options))
    end
  end

  context "with lambda" do
    context "allowed forms" do
      before do
        @user = User.new
        @allowed_forms = [
          Elements::Form.new(
            name: :user, value: ->(obj, s){
              ["api/v1/users/#{@user.id}", {rel: :user}]
            }
          ),
          Elements::Form.new(
            name: :root, value: "api/v1/root", options: {rel: :root}
          ),
        ]
        @allowed_forms.each do |form|
          UserSerializer.form(*form.as_input)
        end

        @options = SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }, without: [:forms])
        })
      end

      it "holds the unwrapped forms" do
        expect(@options.forms.count).to eq(2)

        expect(@options.forms.first.name).to eq(@allowed_forms.first.name)
        expect(@options.forms.first.value).to eq(@allowed_forms.first.value.call(@user, nil).first)
        expect(@options.forms.first.options).to eq(@allowed_forms.first.value.call(@user, nil).last)

        expect(@options.forms.last.name).to eq(@allowed_forms.last.name)
        expect(@options.forms.last.value).to eq(@allowed_forms.last.value)
        expect(@options.forms.last.options).to eq(@allowed_forms.last.options)
      end
    end

    context "injected forms" do
      before do
        @user = User.new
        @allowed_forms = Elements.forms
        @allowed_forms.each do |form|
          UserSerializer.form(*form.as_input)
        end

        #@injected_forms = Helpers.pick(@allowed_forms).inject({}) { |memo, form|
        @injected_forms = [@allowed_forms.first].inject({}) { |memo, form|
          memo[form.name] = ->(obj, s){ ["/api/v1/#{@user.id}/#{form.name}", rel: form.name] }
          memo
        }

        @options = SimpleAMS::Options.new(@user, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            forms: @injected_forms
          })
        })
      end

      it "holds the injected lambda forms" do
        expect(@options.forms.count).to eq(@injected_forms.count)

        @options.forms.each do |form|
          expect(form.name).to eq(@injected_forms.find{|l| l.first == form.name}[0])
          expect(form.value).to eq(@injected_forms[form.name].call(@user, nil).first)
        end
      end
    end
  end
end

