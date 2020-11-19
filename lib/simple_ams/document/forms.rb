require 'simple_ams'

class SimpleAMS::Document::Forms < SimpleAMS::Document::Generics
  def initialize(options)
    @options = options
    @members = options.forms
  end

  class Form < SimpleAMS::Document::Generics::Generic
  end
end
