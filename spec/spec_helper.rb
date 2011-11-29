require "minitest/autorun"
require "minitest/pride"
require "minitest/rails"
require 'minitest/capybara'

require 'database_cleaner'


ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

DatabaseCleaner.strategy = :truncation

class MiniTest::Spec
  include Factory::Syntax::Methods
  # Add methods to be used by all specs here...
  before :each do
    DatabaseCleaner.clean
  end
end

# Uncomment to support fixtures in Model tests...
# require "active_record/fixtures"
class MiniTest::Rails::Model
  # include ActiveRecord::TestFixtures
  # self.fixture_path = File.join(Rails.root, "test", "fixtures")
end

class Object
  def must_be_like other
    gsub(/\s+/, ' ').strip.must_equal other.gsub(/\s+/, ' ').strip
  end
end