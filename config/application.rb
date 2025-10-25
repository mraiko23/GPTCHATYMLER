require_relative "boot"
# Load individual Rails components, excluding ActiveRecord
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"
# require "sprockets/railtie"  # Not needed

Bundler.require(*Rails.groups)
require_relative '../lib/middleware/clacky_health_check'
require_relative '../lib/env_checker'
require_relative '../lib/json_database'
require_relative '../lib/json_model'

module Myapp
  class Application < Rails::Application

    # check environment variables in production
    EnvChecker.check_required_env_vars if Rails.env.production?

    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: false,
        request_specs: false
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    # skip credentials
    config.require_master_key = false

    config.generators.assets = false
    config.generators.helper = false
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    config.autoload_lib(ignore: %w[assets tasks generators rails middleware])
    config.middleware.insert_before Rails::Rack::Logger, ClackyHealthCheck

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Application name configuration
    config.x.appname = "Telegram AI Chat"

    # Initialize JSON Database
    config.after_initialize do
      JsonDatabase.initialize!
    end
    
    # Configure Active Job queue adapter to use inline (since we're not using ActiveJob with DB)
    config.active_job.queue_adapter = :inline

    # Use custom MailDeliveryJob that inherits from ApplicationJob
    config.action_mailer.delivery_job = "MailDeliveryJob"
  end
end
