# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'
require 'maxmind/db'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DaoServer
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.time_zone = 'Singapore'
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: %i[get post options]
      end
    end

    config.action_mailer.delivery_method = :postmark
    config.action_mailer.postmark_settings = { api_token: ENV['POSTMARK_API_TOKEN'] }

    config.challenges = config_for(:challenges)
    config.comments = config_for(:comments)
    config.ethereum = config_for(:ethereums)
    config.ips = config_for(:ips)
    config.nonces = config_for(:nonces)
    config.proposals = config_for(:proposals)

    config.country_ips = MaxMind::DB.new(
      ENV.fetch('IP_DB') { 'config/GeoLite2-Country.mmdb' },
      mode: MaxMind::DB::MODE_MEMORY
    )
    config.countries = JSON.parse(File.read('config/countries.json'))
    config.income_ranges = JSON.parse(File.read('config/income_ranges.json'))
    config.industries = JSON.parse(File.read('config/industries.json'))
    config.rejection_reasons =
      JSON.parse(File.read('config/rejection_reasons.json'))
  end
end
