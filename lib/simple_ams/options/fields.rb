require 'simple_ams'

class SimpleAMS::Options
  class Fields < Array
    include SimpleAMS::Options::Concerns::Filterable
  end
end
