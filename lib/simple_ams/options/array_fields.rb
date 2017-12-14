require "simple_ams"

class SimpleAMS::Options
  class ArrayFields
    attr_reader :members

    def initialize(members)
      @members = members
    end

    def &(other_fields)
      return self.class.new(
        members.select{|m|
          other_fields.has?(m)
        }
      )
    end

    def method_missing(meth, *args, &block)
      if members.respond_to? meth
        members.send(meth, *args, &block)
      else
        super
      end
    end

    def has?(member)
      members.include?(member)
    end
  end

  class Fields < ArrayFields
  end

  class Includes < ArrayFields
  end
end
