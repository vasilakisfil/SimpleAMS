require 'simple_ams'

class SimpleAMS::Options
  class Generics < Array
    include SimpleAMS::Options::Concerns::Filterable

    def volatile?
      any?(&:volatile?)
    end

    class Option
      include SimpleAMS::Options::Concerns::NameValueHash
    end
  end
end
