require "simple_ams"

module SimpleAMS
  class Document::Generics < Document::Links
    def initialize(options)
      @options = options
      @members = options.generics
    end

    class Option < Document::Links::Link
    end
  end
end

