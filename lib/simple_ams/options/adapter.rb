require "simple_ams"

class SimpleAMS::Options
  class Adapter
    include SimpleAMS::Options::Concerns::ValueHash

    alias_method :klass, :value
  end
end
