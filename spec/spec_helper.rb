require "bundler/setup"
require "simple_ams"
require 'date'
require 'securerandom'
require 'faker'
require 'pry'

Dir[
  Pathname(
    File.expand_path(File.dirname(__FILE__))
  ).join('support/**/*.rb')
].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec.configure do |config|
  config.after(:each) do
    Helpers.reset!(User)
  end
end
