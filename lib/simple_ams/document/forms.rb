require "simple_ams"

module SimpleAMS
  class Document::Forms < Document::Links
    def initialize(options)
      super
      @members = options.forms
    end

    class Form < Document::Links::Link
    end
  end
end
