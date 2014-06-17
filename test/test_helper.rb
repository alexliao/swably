# ENV["RAILS_ENV"] = "test" # This line is no effect, because database is already loaded before this line is run, with default value "development"
# To ensure running test with test database, type command line "RAILS_ENV=test bundle exec rake test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
