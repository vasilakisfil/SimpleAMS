require 'simple_ams'

class SimpleAMS::Options
  class Relations < Array
    attr_reader :relations, :includes

    def initialize(relations, includes = nil)
      @relations = relations
      @includes = includes

      super(relations.map { |rel| Relations::Relation.new(*rel) })
    end

    def available
      return @available ||= self if includes.nil?
      return @available ||= [] if includes.empty?

      @available ||= self.select  do |relation|
        includes.include?(relation.name)
      end
    end

    class Relation
      attr_reader :type, :name, :options, :embedded
      def initialize(type, name, options = {}, embedded)
        @type = type.to_sym
        @name = name.is_a?(String) ? name.to_sym : name
        @options = options
        @embedded = embedded

        @many = type == :has_many
      end

      alias relation name

      def raw
        [type, name, options, embedded]
      end

      def collection?
        @many
      end

      def single?
        !collection?
      end

      private

      attr_writer :type, :name, :options
    end
  end
end
