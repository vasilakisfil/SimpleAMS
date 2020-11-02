require 'simple_ams'

module SimpleAMS
  class Document::Links < Document::Generics
    def initialize(options)
      @options = options
      @members = options.links
    end

    class Generic < Document::Generics::Generic
    end
  end
end
