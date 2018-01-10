require "simple_ams"

class SimpleAMS::Options
  class Metas < Array
    include SimpleAMS::Options::Concerns::Filterable

    #TODO: should it check empty value ?
    class Meta
      include SimpleAMS::Options::Concerns::NameValueHash
    end
  end
end
