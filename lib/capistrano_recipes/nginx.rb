require 'capistrano_recipes/utils'

Capistrano::Configuration.instance.load do
  # Nginx unix-user
  _cset(:nginx_user) { "deploy" }
  # Where nginx logs will live
  _cset(:nginx_log_path) { "#{shared_path}/log/nginx"}

  # Where your nginx lives. Usually +/etc/nginx+ or +/opt/nginx+ or +/usr/local/nginx+ for source compiled.
  _cset(:nginx_path_prefix) { "/etc/nginx" }
  # Nginx port for your application
  _cset(:nginx_port) { 80 }
  _cset(:nginx_use_ssl) { false }

  # Path to the nginx erb template to be parsed before uploading to remote
  _cset(:nginx_config_template) { "nginx/nginx_#{app_server}.conf.erb" }

  # Path to where your remote config will reside
  _cset(:nginx_config_path) { "#{nginx_path_prefix}/conf.d/#{application_domain}.conf" }

  # Nginx tasks are not *nix agnostic, they assume you're using Debian/Ubuntu.
  # Override them as needed.
  namespace :nginx do
    desc "Parses and uploads nginx config file for this app."
    task :setup, :roles => :app, :except => {:no_release => true} do
      run "mkdir -p #{nginx_log_path}"
      cp_template nginx_config_template, nginx_config_path
      sudo_commands do
        run "#{sudo} chown root:root #{nginx_config_path}"
        run "#{sudo} chmod 600 #{nginx_config_path}"
      end
      restart
    end

    %w[start stop restart reload status].each do |command|
      desc "#{command} nginx"
      task command, :roles => :app, :except => {:no_release => true} do
        sudo_commands do
          run "#{sudo} service nginx #{command}"
        end
      end
    end
  end

  after 'deploy:setup' do
    nginx.setup
  end
end

