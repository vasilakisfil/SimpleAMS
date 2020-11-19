class Elements
  class << self
    def method_missing(meth, *args)
      if new.respond_to? meth
        new.send(meth, *args)
      else
        super
      end
    end

    def respond_to_missing?(meth, _)
      new.respond_to?(meth) || super
    end
  end

  def primary_id(*args)
    PrimaryId.new(*args)
  end

  def type(*args)
    Type.new(*args)
  end

  def link(*args)
    Link.new(*args)
  end

  def links
    rand(3..12).times.map { Link.new }
  end

  def fields
    rand(3..12).times.map { Field.new }
  end
  alias attributes fields

  def includes
    rand(3..12).times.map { Include.new }
  end

  def meta(*args)
    Meta.new(*args)
  end

  def metas
    rand(3..12).times.map { Meta.new }
  end

  def form(*args)
    Form.new(*args)
  end

  def forms
    rand(3..12).times.map { Form.new }
  end

  def generic(*args)
    Generic.new(*args)
  end

  def generics
    rand(3..12).times.map { Generic.new }
  end

  def as_elements_for(hash, klass:)
    hash.map do |key, value|
      klass.new({
        name: key,
        value: value.is_a?(Array) ? value.first : value,
        options: value.is_a?(Array) ? value.last : {}
      })
    end
  end

  def as_options_for(elements)
    elements.each_with_object({}) do |element, memo|
      memo[element.name] = [element.value, element.options]
    end
  end

  def adapter(*args)
    Adapter.new(*args)
  end

  class Field
    attr_reader :name

    def initialize(name: nil)
      @name = name || Faker::Lorem.word
    end

    def as_input
      name
    end
  end
  class Include < Field; end

  class NameValueHash
    attr_reader :name, :value, :options

    def initialize(name: nil, value: nil, options: nil)
      @name = name || Helpers::Options.single.to_sym
      @value = value || Faker::Lorem.word
      @options = if @value.is_a?(Proc)
                   options || {}
                 else
                   options.nil? ? Helpers::Options.hash : options
                 end
    end

    def as_input
      [@name, @value, @options]
    end

    def as_lambda_input(explicit_options: false)
      if @value.is_a?(Proc)
        if explicit_options
          [@name, @value, @options]
        else
          [@name, @value]
        end
      else
        [@name, -> { [@value, @options] }]
      end
    end

    # TODO: do we need that?
    def value_options
      [@value, @options]
    end
  end

  class Link < NameValueHash; end

  class Meta < NameValueHash; end

  class Form < NameValueHash; end

  class Generic < NameValueHash; end

  class ValueHash
    attr_reader :value, :options

    def initialize(value: nil, options: {})
      @value = value || Helpers::Options.single.to_sym
      @options = options == {} ? Helpers::Options.hash : options
    end

    alias name value

    def as_injected
      { self.class.to_s.downcase.to_sym => as_input }
    end

    def as_input(extra = {})
      [@value, @options.merge(extra)]
    end

    def as_lambda_input(explicit_options: false)
      if @value.is_a?(Proc)
        if explicit_options
          [@value, @options]
        else
          @value
        end
      else
        -> { [@value, @options] }
      end
    end
  end

  class Adapter < ValueHash
    def initialize(value: nil, options: {})
      @value = value || Helpers::Adapter1
      super
    end
  end

  class PrimaryId < ValueHash; end

  class Type < ValueHash; end
end
