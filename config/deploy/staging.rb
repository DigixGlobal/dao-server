# frozen_string_literal: true

set :stage, :staging
server 'info01-dev', user: 'appuser', roles: %w[app web db]

set :default_env,
    histfile: '/dev/null',
    rails_env: 'staging',
    dao_staging_database_password: ENV['DAO_STAGING_DATABASE_PASSWORD'],
    dao_staging_secret_key_base: ENV['DAO_STAGING_SECRET_KEY_BASE'],
    info_server_url: ENV['INFO_SERVER_URL'],
    postmark_api_token: ENV['POSTMARK_API_TOKEN'],
    whitelist_ips: ENV['WHITELIST_IPS']
