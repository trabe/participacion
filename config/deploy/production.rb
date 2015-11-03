set :deploy_to, deploysecret(:deploy_to)
set :server_name, deploysecret(:server_name)
set :db_server, deploysecret(:server)
set :branch, ENV['BRANCH'] || ENV['branch'] || ENV['tag'] || 'master'
set :ssh_options, port: deploysecret(:ssh_port)
set :stage, :production
set :rails_env, :production

server deploysecret(:server), user: deploysecret(:user), roles: %w(web app db importer cron)
