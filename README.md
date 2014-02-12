## capistrano_recipes

Bunch of capistrano recipes

Inspired by https://github.com/elegion/capistrano-scrip

## Installation

Add `capistrano_recipes` to your application's Gemfile:

    gem 'capistrano_recipes', :git => 'git://github.com/topmonks/capistrano_recipes.git'

And then install the bundle:

    $ bundle

## Usage

First, initialize capistrano:

    capify .
    
This will create `./Capfile ` and `./config/deploy.rb`. Edit `./config/deploy.rb` and load recipes required
for your application:

    require "capistrano_recipes/nginx"
    require "capistrano_recipes/mysql"
    require "capistrano_recipes/host"
    require "capistrano_recipes/symlinks"

Then run `cap host:setup deploy:initial` to make your first deploy. Use `cap deploy:migrations` for next deploys.

### Example of rails app deployment

`config/deploy.rb`:
    set(:symlink_yml_examples) { ["application", "credit_card_info"]} #If you have any config/*.example.yml files. They must exist on remote server in shared/config directory
    set(:link_uploads) { true }
    set(:link_uploads_path) { "uploads" } #or public/uploads. On remote server must exist the same path in shared directory!

    default_run_options[:pty] = true     # Must be set for the password prompt to work
    set :use_sudo, false                 # Don't use sudo (deploy user must have very limited permissions in system)

    set :default_stage, "staging"        # Deploy on staging server by default

    # Configure capistrano deploy strategy
    set :repository, '.'
    set :deploy_via, :remote_cache
    set :copy_exclude, [".git", "coverage", "results", "tmp", "public/system", "builder"]

    set :root_user, "user"               # User with root privileges on server. You will need him only for host:setup
                                         # and *:setup_host tasks. This will not be used during deploy,
                                         # deploy:migrations and other common tasks.
    set :user, "app_name"                # Deployer user
    set :group, "app_name"               # Deployer group
    set :user_home_path, "/home/deploy"  # Deployer home on target system (used in host:setup when creating new user)
    set(:deploy_to) { "/var/www/#{application}" } # Path where to deploy your application

    role(:web) { domain }                         # Your HTTP server, Apache/etc
    role(:app) { domain }                         # This may be the same as your `Web` server
    role(:db, :primary => true) { domain }        # This is where Rails migrations will run

    require "capistrano_colors"                   # Colorized output in console (gem install capistrano_colors)
    require "capistrano/ext/multistage"           # Enable multistage deployment
    require "capistrano_recipes/nginx"            # Use nginx as web-server
    require "capistrano_recipes/mysql"            # Use mysql as db-server
    require "capistrano_recipes/host"             # Require host:setup task
    require "capistrano_recipes/monit"            # Use monit as monitoring system
    require "capistrano_recipes/ruby/thin"        # Use thing as app-server
    require "capistrano_recipes/ruby/rails"       # Load rails-specific recipes
    require "bundler/capistrano"                  # Use bundler on server
    load "deploy/assets"                          # Use rails assets pipeline

`config/deploy/production.rb`

    set :application, "app_name"                  # Application name for production
                                                  # (it's used in some configs and paths)
    set :application_domain, "app_domain.com"     # Domain for production server
    set :domain, "192.168.1.1"                    # Server address where to deploy production

    set :rails_env, 'production'
    set :branch, 'production'
    set :thin_port, 4300
    set :app_server, "thin"
    set :nginx_use_ssl, true
    set :thin_servers, 3

`config/deploy/staging.rb`

    set :application, "app_name_test"             # Application name for staging server
    set :application_domain, "qa.app_domain.com"  # Domain for staging server
    set :domain, "192.168.1.1"                    # Server address where to deploy staging

    set :rails_env, 'staging'
    set :branch, 'staging'
    set :thin_port, 4400
    set :app_server, "thin"
    set :nginx_use_ssl, false
    set :thin_servers, 3

Then execute `cap host:setup deploy:initial nginx:enable` to create user and config files and perform initial deploy,
then symlink `/etc/nginx/sites-available/app_name.conf` to `/etc/nginx/sites-enabled/app_name.conf`.
On next deploy just run `cap deploy:migrations` to deploy new application version.

`cap host:setup` will perform:

 * `host:create_user` - creates `:user` on target system (if doesn't exist yet)
 * `host:ssh_copy_id` - adds `~/.ssh/id_rsa.pub` from local machine to `authorized_keys` on target machine for `:user`
 * Then it performs `*:setup_host` for all loaded recipes:
   * `nginx:setup_host` - creates nginx config file in `/etc/nginx/sites-available/app_name.conf`, grants user
     permissions to modify it. Creates `#{deploy_to}/shared/logs/nginx` directory and grants nginx permissions to
     write there.
   * `mysql:setup_host` - creates mysql user with random password grants him administrative permissions for application
     database (`:database_name`). Then creates `:database_config_template` in `#{deploy_to}/shared/config/database.yml`,
     grants it 440 permissions (only user and group can read it). It will be symlinked to
     `#{deploy_to}/current/config/database.yml` on each deploy.
   * `monit:setup_host` - creates monit config file for thin in `/etc/monit/conf.d/app_name-thin`, grants user
     permissions to modify it.
   * `thin:setup_host` - creates directory for thin sockets (if `:thin_socket` is set), creates thin config file in
     `#{deploy_to}/shared/config/thin.yml`

## Config templates

Capistrano_recipes uses ERB to parse nginx/monit/thin/etc templates. You can see default config templates at github:
https://github.com/rubydev/capistrano_recipes/tree/master/templates

If you don't like any of this, you can replace it with you own:

* Put your template in `config/deploy/templates/#{template_name}`
* Or change `*_template` variable value to reflect your template path: `set :monit_config_template, 'deploy/monit.erb'`

## Contributing

1. Fork
2. Create your feature branch (`git checkout -b my_branch`)
3. Commit your changes (`git commit -am "my cool feature"`)
4. Push to the branch (`git push origin my_branch`)
5. Create new Pull Request
