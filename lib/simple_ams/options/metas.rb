require 'simple_ams'

class SimpleAMS::Options
  class Metas < Generics
    include SimpleAMS::Options::Concerns::Filterable

    class Meta < Generics::Option
      include SimpleAMS::Options::Concerns::NameValueHash
    end
  end
end
