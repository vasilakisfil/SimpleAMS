class SimpleAMS::Options
  module Concerns
    module TrackedProperties
      Tracked = Struct.new(:value) do
        def volatile?
          return @volatile if defined?(@volatile)

          @volatile ||= value.volatile?
        end
      end

      def initialize_tracking!
        @tracked_properties = {}
      end

      def clean_volatile_properties!
        @tracked_properties = @tracked_properties.select { |_k, v| !v.volatile? }
      end

      def tracked(meth)
        @tracked_properties[meth] ||= Tracked.new
      end
    end
  end
end
