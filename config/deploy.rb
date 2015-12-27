Airbrussh.configure do |config|
  config.command_output = true
end


# config valid only for Capistrano 3.4
lock '3.4.0'

# setup repo details
set :user, 'user_name'
set :pty, true
set :scm, :git
set :repo_url, 'git@github.com:project.git'
set :keep_releases, 3

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache vendor/bundle public/assets} #rails3

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

set :delayed_job_args, "-n 2" # number of workers
set :whenever_roles, ->{ :app } # by defaut whenever maps to db role.
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

before "deploy:restart", "deploy:asset_precompile"
after "deploy:restart", "deploy:cleanup_assets"

namespace :deploy do

  desc 'assets precompile'
  task :asset_precompile do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        with rails_env: fetch(:stage) do
          execute :rake, "assets:precompile"
        end
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
      # execute "cd '#{release_path}' && RAILS_ENV=#{fetch(rails_env)} nice -n 15 script/delayed_job -n 3 restart"  # custom cmd.
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    # on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #  execute :rake, 'cache:clear'
      invoke 'delayed_job:restart' #https://github.com/collectiveidea/delayed_job/wiki/Delayed-Job-tasks-for-Capistrano-3
      # end
    # end
  end

end
