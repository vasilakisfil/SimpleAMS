require "simple_ams"

class SimpleAMS::Options
  class Forms < Array
    include SimpleAMS::Options::Concerns::Filterable

    class Form
      include SimpleAMS::Options::Concerns::NameValueHash
    end
  end
end

