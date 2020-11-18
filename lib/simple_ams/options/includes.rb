require 'simple_ams'

class SimpleAMS::Options
  class Includes < Array
    include SimpleAMS::Options::Concerns::Filterable
  end
end
