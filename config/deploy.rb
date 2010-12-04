require 'capistrano_colors'
require 'capistrano/ext/multistage'
require 'rvm/capistrano'
require 'bundler/capistrano'
require 'hoptoad_notifier/capistrano'

load 'recipes/prompt.rb'
load 'recipes/rvm.rb'
load 'recipes/passenger.rb'
load 'recipes/postgresql.rb'
load 'recipes/whenever.rb'
load 'recipes/stack.rb'
load 'recipes/newrelic.rb'
load 'recipes/log.rb'

default_run_options[:pty] = true

set :application, "ffcrm"
set :domain, "crossroadsint.org"
set :stages, %w(preview beta live)
set :default_stage, "preview"
set :keep_releases, 3

set :bundle_without, [:cucumber, :development, :test]

set :scm, :git
set :repository, "git://github.com/crossroads/fat_free_crm.git"
set :git_enable_submodules, 1
set :deploy_via, :remote_cache

set :packages_for_project, %w(ImageMagick-devel)
set :gems_for_project, "bundler"

set :rvm_ruby_string, "1.9.2"
set :passenger_version, "3.0.0"

set :httpd_user, "apache"
set :httpd_grp,  "apache"

#
# To get going from scratch:
#
# cap deploy:cold
# cap crm:setup
# cap crm:demo
#

namespace :crm do

  desc "Load crm settings"
  task :settings do
    run "if [ -f #{shared_path}/settings.sed ]; then sed -i -f #{shared_path}/settings.sed #{current_path}/vendor/plugins/crm_crossroads/config/settings.yml; fi"
    run "cd #{current_path} && bundle exec rake crm:settings:load PLUGIN=crm_crossroads RAILS_ENV=production"
  end

  namespace :setup do

    desc "Prepare the database and load default application settings (destroys all data)"
    task :default do
      prompt_with_default("Username", :admin_username, "admin")
      prompt_with_default("Password", :admin_password, "admin")
      prompt_with_default("Email", :admin_email, "admin@crossroadsint.org")
      run "cd #{current_path} && RAILS_ENV=production rake crm:setup USERNAME=#{admin_username} PASSWORD=#{admin_password} EMAIL=#{admin_email} PROCEED=true"
    end

   desc "Creates an admin user"
    task :admin do
      prompt_with_default("Username", :admin_username, "admin")
      prompt_with_default("Password", :admin_password, "admin")
      prompt_with_default("Email", :admin_email, "admin@crossroadsint.org")
      run "cd #{current_path} && RAILS_ENV=production rake crm:setup:admin USERNAME=#{admin_username} PASSWORD=#{admin_password} EMAIL=#{admin_email}"
    end

  end

  desc "Load demo data (wipes database)"
  task :demo do
    run "cd #{current_path} && RAILS_ENV=production rake crm:demo:load"
  end

  namespace :crossroads do
    desc "Seed crossroads data (tags and customfields, etc.)"
    task :seed do
      run "cd #{current_path} && RAILS_ENV=production rake crm:crossroads:seed"
    end
  end

end

namespace :deploy do

  desc "Deploy permissions hacks"
  task :user_permissions do
    sudo "chown -R #{user} #{deploy_to}"
  end

  desc "Setting proper permissions for apache user"
  task :set_permissions do
    sudo "chown -R #{httpd_user}:#{httpd_grp} #{release_path}/"
    sudo "chmod -R 750 #{release_path}/"
    sudo "chown -R #{httpd_user}:#{httpd_grp} #{deploy_to}/shared/"
    sudo "chmod -R 750 #{deploy_to}/shared/"

    # deploying user needs ownership of REVISION file for hoptoad deployment notify
    sudo "chmod 755 #{release_path}/"
    sudo "chmod 754 #{release_path}/REVISION"
  end

  task :mods_enabled do
    sudo "ln -sf /etc/httpd/mods-available/expires.load /etc/httpd/mods-enabled"
    sudo "ln -sf /etc/httpd/mods-available/rewrite.load /etc/httpd/mods-enabled"
  end

  desc "Create dropbox log"
  task :dropbox_log do
    run "if [ ! -f #{shared_path}/log/dropbox.log ]; then sudo -p 'sudo password: ' touch #{shared_path}/log/dropbox.log; fi"
  end

  desc "Migrate plugins"
  task :migrate_plugins do
    run "cd #{current_path} && RAILS_ENV=production rake db:migrate:plugins"
  end

end

namespace :stack do
  desc "Generate ssh key for adding to github public keys"
  task 'ssh-keygen' do
    puts; puts
    puts "====================================================================="
    puts "If capistrano stops here then paste the following key into github and"
    puts "run \"cap deploy:cold\" again"
    puts "====================================================================="
    puts; puts
    run "if ! (ls $HOME/.ssh/id_rsa); then (ssh-keygen -N '' -t rsa -q -f $HOME/.ssh/id_rsa && cat $HOME/.ssh/id_rsa.pub) && exit 1; fi"
  end
end

before "deploy:cold",           "stack:ssh-keygen"
before "deploy:cold",           "deploy:mods_enabled"
before "deploy",                "deploy:user_permissions"
before "deploy:symlink",        "deploy:dropbox_log"
after  "deploy:migrate",        "deploy:migrate_plugins"

before "deploy:update_crontab", "deploy:user_permissions"
after  "deploy:update_crontab", "deploy:set_permissions"
