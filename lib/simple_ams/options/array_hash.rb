require "simple_ams"

class SimpleAMS::Options
  class ArrayHash < Array
    def &(other_fields)
      return self.class.new(
        self.select{|m|
          other_fields.has?(m)
        }
      )
    end

    def has?(member)
      self.include?(member)
    end
  end

  class Fields < ArrayHash; end

  class Includes < ArrayHash; end
end
