require "simple_ams"

class SimpleAMS::Options
  class Links < Array
    include SimpleAMS::Options::Concerns::Filterable

    class Link
      include SimpleAMS::Options::Concerns::NameValueHash
    end
  end
end
