# config valid only for current version of Capistrano
lock '3.4.0'

def deploysecret(key)
  @deploy_secrets_yml ||= YAML.load_file('config/deploy-secrets.yml')[fetch(:stage).to_s]
  @deploy_secrets_yml.fetch(key.to_s, 'undefined')
end

set :rails_env, fetch(:stage)
set :application, 'participacion'

set :full_app_name, deploysecret(:full_app_name)

set :server, deploysecret(:server)
#set :repo_url, 'git@github.com:consul/consul.git'
# If ssh access is restricted, probably you need to use https access
set :repo_url, 'http://git.cixug.es/osl/participacion.git'

#set :scm, :git
set :revision, `git rev-parse --short #{fetch(:branch)}`.strip

set :log_level, :info
set :pty, true
set :use_sudo, false

set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{log tmp public/system public/assets}

set :keep_releases, 5

set :local_user, ENV['USER']

# Run test before deploy
set :tests, ["spec"]

set :delayed_job_workers, 2

# Config files should be copied by deploy:setup_config
set(:config_files, %w(
  log_rotation
  database.yml
  secrets.yml
))

set :whenever_roles, -> { :cron }

set :passenger_restart_with_touch, false

namespace :deploy do
  # Check right version of deploy branch
  # before :deploy, "deploy:check_revision"
  # Run test aund continue only if passed
  # before :deploy, "deploy:run_tests"

  # Custom compile and rsync of assets - works, but it is very slow
  #after 'deploy:symlink:shared', 'deploy:compile_assets_locally'

  after :finishing, 'deploy:cleanup'
  # Restart unicorn
  # Restart Delayed Jobs
  after 'deploy:published', 'delayed_job:restart'
  after 'deploy:published', 'cache:clear'
end
