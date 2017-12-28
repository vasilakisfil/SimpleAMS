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

  def link(*args)
    Link.new(*args)
  end

  def meta(*args)
    Meta.new(*args)
  end

  def adapter(*args)
    Adapter.new(*args)
  end

  class NameValueHash
    attr_reader :name, :value, :options

    def initialize(name: nil, value: nil, options: {})
      @name = name || Helpers::Options.single
      @value = value || Faker::Lorem.word
      @options = options == {} ? Helpers::Options.hash : options
    end

    def as_input
      [@name, @value, @options]
    end
  end

  class Link < NameValueHash; end

  class Meta < NameValueHash; end

  class ValueHash
    attr_reader :value, :options

    def initialize(value: nil, options: {})
      @value = value || Faker::Lorem.word
      @options = options == {} ? Helpers::Options.hash : options
    end

    alias :name :value

    def as_input
      [@value, {options: @options}]
    end
  end

  class Adapter < ValueHash; end
end
