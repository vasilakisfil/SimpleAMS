require 'simple_ams'

class SimpleAMS::Options
  class Links < Generics
    include SimpleAMS::Options::Concerns::Filterable

    class Link < Generics::Option
      include SimpleAMS::Options::Concerns::NameValueHash
    end
  end
end
