require "simple_ams"

class SimpleAMS::Options
  class PrimaryId
    include SimpleAMS::Options::Concerns::ValueHash
  end
end
