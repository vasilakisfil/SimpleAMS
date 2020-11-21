require 'simple_ams'

class SimpleAMS::Document::Links < SimpleAMS::Document::Generics
  def initialize(options)
    @options = options
    @members = options.links
  end

  class Generic < SimpleAMS::Document::Generics::Generic
  end
end
