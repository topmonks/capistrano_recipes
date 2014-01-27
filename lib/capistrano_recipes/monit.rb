require 'capistrano_recipes/utils'

# monit is a free, open source process supervision tool for Unix and Linux.
Capistrano::Configuration.instance.load do

  # Path to monit binary on server
  _cset(:monit_command) { "monit" }
  password_prompt_set :monit_admin_pass

  namespace :monit do
    desc "Setup all Monit configuration"
    task :setup do
      sudo_commands do
        run "#{sudo} mkdir -p /etc/monit/conf.d"
        run "#{sudo} mkdir -p /var/lib/monit"
        run "#{sudo} touch id"
      end
      monit_conf = "/etc/monit.conf"
      cp_template("monit/monitrc.erb", monit_conf)
      sudo_commands do
        run "#{sudo} chown root:root #{monit_conf}"
        run "#{sudo} chmod 600 #{monit_conf}"
      end
      resque_worker
      mongodb
      redis
      neo4j
      nginx
      thin
      reload
    end

    task(:mongodb, roles: :app) { monit_config "monit/mongodb.conf.erb", "mongodb", false }
    task(:redis, roles: :app) { monit_config "monit/redis.conf.erb", "redis", false }
    task(:nginx, roles: :app) { monit_config "monit/nginx.conf.erb", "nginx", false }
    task(:thin, roles: :app) { monit_config "monit/nginx/thin.conf.erb", "thin" }
    task(:neo4j, roles: :app) { monit_config "monit/neo4j.conf.erb", "neo4j" }
    task(:resque_worker, roles: :app) { monit_config "monit/resque_worker.conf.erb", "resque_worker" }

    %w[start stop restart reload].each do |command|
      desc "Run Monit #{command} script"
      task command do
        sudo_commands do
          run "#{sudo} service monit #{command}"
        end
      end
    end
  end

  def monit_config(name, dest, uniq = true)
    uniq_name = uniq ? "#{application}-#{dest}" : dest
    destination = "/etc/monit/conf.d/#{uniq_name}.conf"
    cp_template name, destination
    sudo_commands do
      run "#{sudo} chown root:root #{destination}"
      run "#{sudo} chmod 600 #{destination}"
    end
  end

  after "deploy:setup", "monit:setup"
end
