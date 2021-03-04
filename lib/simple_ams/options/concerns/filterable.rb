require 'simple_ams'

class SimpleAMS::Options
  module Concerns::Filterable
    # for optimizing performance, ask only the first element
    # other idea is to create another module just for (Name)ValueHash objects
    def &(other)
      other_is_object = (other[0].respond_to?(:name) && other[0].class != Symbol)

      self.class.new(
        self.select do |m|
          if other_is_object
            other.include?(m.name)
          else
            other.include?(m)
          end
        end
      )
    end

    # for optimizing performance, ask only the first element of self and save it as state
    def include?(member)
      @self_is_object = self[0].respond_to?(:name) && self[0].class != Symbol unless defined?(@self_is_object)

      if @self_is_object
        any? { |s| s.name == member }
      else
        super
      end
    end

    def raw
      if self[0].respond_to?(:raw)
        map(&:raw)
      else
        map { |i| i }
      end
    end
  end
end
