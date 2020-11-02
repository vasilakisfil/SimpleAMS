require 'simple_ams'

class SimpleAMS::Options
  class Forms < Generics
    include SimpleAMS::Options::Concerns::Filterable

    class Form < Generics::Option
      include SimpleAMS::Options::Concerns::NameValueHash
    end
  end
end
