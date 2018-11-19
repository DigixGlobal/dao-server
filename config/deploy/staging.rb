set :stage, :staging
server 'kycapi-dev', user: 'appuser', roles: %w{app web db}

set :default_env, {
  histfile: "/dev/null",
  rails_env: "staging",
  info_server_url: ENV['INFO_SERVER_URL'],
  daoserver_staging_database_password: ENV['DAOSERVER_STAGING_DATABASE_PASSWORD'],
  daoserver_staging_secret_key_base: ENV['DAOSERVER_STAGING_SECRET_KEY_BASE']
}
