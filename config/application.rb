require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

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

    def add_user(address, uid)
      return if User.find_by(address: address)
      u = User.new(address: address, uid: uid)
      u.save
    end

    config.after_initialize do
      add_user('0x68911e512a4ecbd12d5dbae3250ff2c8e5850b60', '01')
      add_user('0x300ac2c15a6778cfdd7eaa6189a4401123ff9dda', '02')
      add_user('0x602651daaea32f5a13d9bd4df67d0922662e8928', '03')
      add_user('0x9210ddf37582861fbc5ec3a9aff716d3cf9be5e1', '04')
      add_user('0xe02a693f038933d7b28301e6fb654a035385652d', '05')
      add_user('0xcbe85e69eec80f29e9030233a757d49c68e75c8d', '06')
      add_user('0x355fbd38b3219fa3b7d0739eae142acd9ea832a1', '07')
    end


  end
end
