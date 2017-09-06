require "SimpleAMS"

module SimpleAMS::DSL
  def self.included(host_class)
    host_class.extend ClassMethods
  end

  module ClassMethods
    def attributes
      @config ||= Configuration.new
    end

    def root
      yield config
    end
  end
end

