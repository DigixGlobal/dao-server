# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "dao_server"
set :repo_url, "git@github.com:DigixGlobal/dao-server.git"

set :branch, "staging"

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :deploy_to, "/home/appuser/apps/dao_server"
set :pty, true
set :keep_releases, 5
set :user, 'appuser'
set :puma_threads,    [4, 16]
set :puma_workers,    0
set :puma_bind,       "tcp://127.0.0.1:3000"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord
set :rvm_type, :user                     # Defaults to: :auto
set :rvm_ruby_version, '2.5.3@daoserver'


set :puma_conf, "#{shared_path}/config/puma.rb"

namespace :deploy do
  before 'check:linked_files', 'puma:config'
  after 'deploy', 'puma:restart'
end
