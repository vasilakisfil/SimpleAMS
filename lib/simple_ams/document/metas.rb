require 'simple_ams'

class SimpleAMS::Document::Metas < SimpleAMS::Document::Generics
  def initialize(options)
    @options = options
    @members = options.metas
  end

  class Meta < SimpleAMS::Document::Generics::Generic
  end
end
