# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require 'shoulda'
require 'mocha/setup'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

if Rails.version.to_f < 5.2
  ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)
else
  ActiveRecord::MigrationContext.new(File.expand_path("../dummy/db/migrate/", __FILE__)).migrate
end

ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)

FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures")