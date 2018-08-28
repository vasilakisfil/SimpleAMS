class Elements
  class << self
    def method_missing(meth, *args)
      if self.new.respond_to? meth
        self.new.send(meth, *args)
      else
        super
      end
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
    (rand(10) + 3).times.map{Link.new}
  end

  def fields
    (rand(10) + 3).times.map{Field.new}
  end
  alias attributes fields

  def includes
    (rand(10) + 3).times.map{Include.new}
  end

  def metas
    (rand(10) + 3).times.map{Meta.new}
  end

  def as_elements_for(hash, klass:)
    hash.map{|key, value|
      klass.new({
        name: key,
        value: value.is_a?(Array) ? value.first : value,
        options: value.is_a?(Array) ? value.last : {}
      })
    }
  end

  def as_options_for(elements)
    elements.inject({}){|memo, element|
      memo[element.name] = [element.value, element.options]
      memo
    }
  end

  def meta(*args)
    Meta.new(*args)
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
      if @value.is_a?(Proc)
        @options = {}
      else
        @options = options == nil ? Helpers::Options.hash : options
      end
    end

    def as_input
      [@name, @value, @options]
    end

    def as_lambda_input
      if @value.is_a?(Proc)
        [@name, @value]
      else
        [@name, ->{ [@value, @options] } ]
      end
    end

    #TODO: do we need that?
    def value_options
      [@value, @options]
    end
  end

  class Link < NameValueHash; end

  class Meta < NameValueHash; end

  class ValueHash
    attr_reader :value, :options

    def initialize(value: nil, options: {})
      @value = value || Helpers::Options.single.to_sym
      @options = options == {} ? Helpers::Options.hash : options
    end

    alias :name :value

    def as_injected
      {self.class.to_s.downcase.to_sym => as_input}
    end

    def as_input(extra = {})
      [@value, @options.merge(extra)]
    end

    def as_lambda_input
      ->{ [@value, @options] }
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
