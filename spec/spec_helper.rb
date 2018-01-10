require "bundler/setup"
require 'simplecov'
SimpleCov.start do
  #TODO: maybe we shouldn't exclude spec/support/* files ?
  add_filter "/spec/"
end
require "simple_ams"
require 'date'
require 'securerandom'
require 'faker'
require 'pry'
require 'rspec/repeat'

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

class RSpec::Repeat::Repeater
  def run(ex, ctx)
    example = current_example(ctx)

    count.each do |i|
      example.instance_variable_set :@exception, nil
      ex.run
      print_failure(i, example) if verbose && !example.exception.nil?
      clear_memoize(ctx) if clear_let
      sleep wait if wait.to_i > 0
    end
  end
end

RSpec.configure do |config|
  config.after(:each) do
    Helpers.reset!(UserSerializer)
  end

  config.include RSpec::Repeat
  config.around :each do |example|
    repeat example, (ENV['SPEC_REPEAT_TIMES'] || 1).to_i.times, verbose: false
  end
end
