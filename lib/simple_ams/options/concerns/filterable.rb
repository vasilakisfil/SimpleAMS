require "simple_ams"

class SimpleAMS::Options
  module Concerns
    #works for arrays that can hold either elements or object that respond_to? :name
    module Filterable
      #for optimizing performance, ask only the first element
      #other idea is to create another module just for (Name)ValueHash objects
      def &(other_filterables)
        other_is_object = other_filterables.first.respond_to?(:name)

        return self.class.new(
          self.select{|m|
            if other_is_object
              other_filterables.include?(m.name)
            else
              other_filterables.include?(m)
            end
          }
        )
      end

      #for optimizing performance, ask only the first element of self and save it as state
      def include?(member)
        unless defined?(@self_is_object)
          @self_is_object = self.first.respond_to?(:name)
        end

        if @self_is_object
          self.map(&:name).include?(member)
        else
          super
        end
      end

      def raw
        if self.first.respond_to?(:raw)
          self.map(&:raw)
        else
          self.map{|i| i}
        end
      end
    end
  end
end
