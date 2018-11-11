require "simple_ams"

module SimpleAMS
  class Document::Metas < Document::Generics
    def initialize(options)
      @options = options
      @members = options.metas
    end

    class Meta < Document::Generics::Generic
    end
  end
end


