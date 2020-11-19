require 'bundler/setup'
require 'simplecov'
SimpleCov.start do
  # TODO: maybe we shouldn't exclude spec/support/* files ?
  add_filter '/spec/'
end
require 'pry'
require 'simple_ams'
require 'date'
require 'securerandom'
require 'faker'

Dir[
  Pathname(
    __dir__
  ).join('support/**/*.rb')
].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec.configure do |config|
  config.after(:each) do
    Helpers.reset!(
      UserSerializer, AddressSerializer, MicropostSerializer, Api::V1::UserSerializer
    )
  end
end
