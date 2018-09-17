require "spec_helper"

RSpec.describe SimpleAMS::DSL, 'forms' do
  context "with no forms" do
    it "returns an empty array" do
      expect(UserSerializer.forms).to eq []
    end
  end

  context "with one form" do
    before do
      @form = Elements.form
      UserSerializer.form(*@form.as_input)
    end

    it "holds the specified form" do
      expect(UserSerializer.forms.count).to eq 1
      expect(UserSerializer.forms.first).to eq @form.as_input
    end
  end

  context "with lambda form" do
    before do
      @form = Elements.form
      UserSerializer.form(*@form.as_lambda_input)
    end

    it "holds the specified form" do
      expect(UserSerializer.forms.count).to eq 1
      expect(UserSerializer.forms.first[1].is_a?(Proc)).to eq true
      expect(UserSerializer.forms.first[1].call).to eq @form.as_input[1..-1]
    end
  end

  context "with multiple forms" do
    before do
      @forms = (rand(10) + 2).times.map{ Elements.form }
      @forms.each{|form|
        UserSerializer.form(*form.as_input)
      }
    end

    it "holds the specified forms" do
      expect(UserSerializer.forms.count).to eq @forms.count
      UserSerializer.forms.each_with_index do |form, index|
        expect(form).to eq @forms[index].as_input
        #just in case
        expect(form).to eq [@forms[index].name, @forms[index].value, @forms[index].options]
      end
    end
  end
end

