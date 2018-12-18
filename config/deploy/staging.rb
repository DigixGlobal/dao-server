set :stage, :staging
server 'info01-dev', user: 'appuser', roles: %w{app web db}

set :default_env, {
  histfile: "/dev/null",
  rails_env: "staging",
  dao_staging_database_password: ENV['DAO_STAGING_DATABASE_PASSWORD'],
  secret_key_base: ENV['DAO_STAGING_SECRET_KEY_BASE'],
  info_server_url: ENV['INFO_SERVER_URL']
}
