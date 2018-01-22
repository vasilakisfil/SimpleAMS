require "simple_ams"

module SimpleAMS
  class Document::Metas < Document::Links
    def initialize(options)
      super
      @members = options.metas
    end

    class Meta < Document::Links::Link
    end
  end
end


