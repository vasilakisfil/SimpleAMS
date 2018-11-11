require "delegate"
require "simple_ams/version"
require "simple_ams/methy"
require "simple_ams/document"
require "simple_ams/dsl"
require "simple_ams/adapters"
require "simple_ams/adapters/ams"
require "simple_ams/adapters/jsonapi"
require "simple_ams/renderer"

require "simple_ams/options/concerns/filterable"
require "simple_ams/options/concerns/name_value_hash"
require "simple_ams/options/concerns/value_hash"
require "simple_ams/options/concerns/tracked_properties"
require "simple_ams/options"
require "simple_ams/options/adapter"
require "simple_ams/options/fields"
require "simple_ams/options/includes"
require "simple_ams/options/generics"
require "simple_ams/options/links"
require "simple_ams/options/metas"
require "simple_ams/options/forms"
require "simple_ams/options/primary_id"
require "simple_ams/options/type"
require "simple_ams/options/relations"

require "simple_ams/document/primary_id"
require "simple_ams/document/fields"
require "simple_ams/document/relations"
require "simple_ams/document/generics"
require "simple_ams/document/links"
require "simple_ams/document/metas"
require "simple_ams/document/forms"
require "logger"

module SimpleAMS
  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    attr_writer :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(self.configuration)
  end

  class Configuration
    attr_accessor :logger

    def initialize
      @logger = ::Logger.new(STDOUT)
    end
  end
end
