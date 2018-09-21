require "spec_helper"

#TODO: add tests for block case in the serializer
RSpec.describe SimpleAMS::Document, 'forms' do
  context "with no forms in general" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
          }).tap{|h| h.delete(:forms)}
        })
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.forms).to eq({})
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.forms).to respond_to(:each)
        @document.forms.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with no injected forms" do
    before do
      @allowed_forms = Elements.forms
      @allowed_forms.each do |form|
        UserSerializer.form(*form.as_input)
      end

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer
          }).tap{|h| h.delete(:forms)}
        })
      )

      @uniq_allowed_forms = @allowed_forms.uniq{|l| l.name}
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.forms).not_to eq({})
      end
    end

    it "returns the allowed ones" do
      expect(@document.forms.map(&:name)).to eq @uniq_allowed_forms.map(&:name)
      expect(@document.forms.map(&:value)).to eq @uniq_allowed_forms.map(&:value)
      expect(@document.forms.map(&:options)).to eq @uniq_allowed_forms.map(&:options)
    end
  end

  context "with empty injected forms" do
    before do
      @allowed_forms = Elements.forms
      @allowed_forms.each do |form|
        UserSerializer.form(*form.as_input)
      end

      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
            forms: []
          })
        })
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.forms).to eq({})
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.forms).to respond_to(:each)
        @document.forms.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
    end
  end

  context "with no allowed forms but injected ones" do
    before do
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, {
          injected_options: Helpers.random_options(with: {
            serializer: UserSerializer,
          })
        })
      )
    end

    describe "members" do
      it "returns an empty array" do
        expect(@document.forms).to eq({})
      end
    end

    describe "values" do
      it "returns an empty array" do
        expect(@document.forms).to respond_to(:each)
        @document.forms.each do |field|
          fail('this should never happen as fields should be empty')
        end
      end
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

      injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        forms: @injected_forms
      })
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, injected_options: injected_options)
      )
    end

    it "holds the uniq union of injected and allowed forms" do
      forms_got = @document.forms
      forms_expected = (Elements.as_elements_for(
        @injected_forms, klass: Elements::Form
      ) + @allowed_forms).uniq{|q| q.name}.select{|l|
        @allowed_forms.map(&:name).include?(l.name) && @injected_forms.keys.include?(l.name)
      }

      expect(forms_got.map(&:name)).to eq(forms_expected.map(&:name))
      expect(forms_got.map(&:value)).to eq(forms_expected.map(&:value))
      expect(forms_got.map(&:options).count).to eq(forms_expected.map(&:options).count)
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

      injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        forms: @injected_forms
      })
      @document = SimpleAMS::Document.new(
        SimpleAMS::Options.new(User.new, injected_options: injected_options)
      )
    end

    it "holds the uniq union of injected and allowed forms" do
      forms_got = @document.forms
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

  context "accessing a form through Document::Form class" do
    before do
      @allowed_forms = Elements.forms
      @allowed_forms.each do |form|
        UserSerializer.form(*form.as_input)
      end
      @injected_forms = Elements.as_options_for(
        Helpers.pick(@allowed_forms)
      )

      injected_options = Helpers.random_options(with: {
        serializer: UserSerializer,
        forms: @injected_forms
      })
      @form_klass = SimpleAMS::Document::Forms.new(
        SimpleAMS::Options.new(User.new, injected_options: injected_options)
      )
    end

    it "holds the uniq union of injected and allowed forms" do
      forms_expected = (Elements.as_elements_for(
        @injected_forms, klass: Elements::Form
      ) + @allowed_forms).uniq{|q| q.name}.select{|l|
        @allowed_forms.map(&:name).include?(l.name) && @injected_forms.keys.include?(l.name)
      }

      forms_expected.each do |form_expected|
        form_got = @form_klass[form_expected.name]
        expect(form_got.name).to eq(form_expected.name)
        expect(form_got.value).to eq(form_expected.value)
        expect(form_got.options).to eq(form_expected.options)
      end
    end
  end
end
