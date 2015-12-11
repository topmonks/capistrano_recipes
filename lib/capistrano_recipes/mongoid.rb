require 'capistrano_recipes/utils'
require 'securerandom'

Capistrano::Configuration.instance.load do

  # Mongoid database password
  _cset(:mongodb_password) { SecureRandom.urlsafe_base64 }
  # Path to where your remote rails database config will reside
  # (it will be symlinked to +#{current_release}/config/database.yml+ on each deploy)
  _cset(:mongoid_config_path) { "#{shared_path}/config/mongoid.yml" }
  # Path to the rails database erb template to be parsed before uploading to remote server
  _cset(:mongoid_config_template) { "mongoid.yml.erb" }

  namespace :mongoid do
    desc "Create"
    task :setup, :roles => :db, :except => {:no_release => true} do
      if not remote_file_exists?(mongoid_config_path)
        cp_template(mongoid_config_template, mongoid_config_path)
        password_prompt_set(:mongo_admin_username)
        password_prompt_set(:mongo_admin_password)
        run "mongo -u #{mongo_admin_username} -p #{mongo_admin_password} admin --eval \"db.getSiblingDB('#{application}').addUser('#{application}', '#{mongodb_password}');\""
      end
    end

    %w[start stop restart status].each do |command|
      desc "#{command} mongodb"
      task command, :roles => :db, :except => {:no_release => true} do
        sudo_commands do
          run "#{sudo} service mongod #{command}"
        end
      end
    end

    task :create_symlink, roles: :app do
      run "ln -nfs #{shared_path}/config/mongoid.yml #{release_path}/config/mongoid.yml"
    end


    task :dump, :roles => :db, :only => {:primary => true} do
      prepare_from_yaml
      run "mongodump #{auth_options} -h #{db_host} --port #{db_port} -d #{db_name} -o #{db_backup_path}" do |ch, stream, out|
        puts out
      end
    end

    desc "Restores the database from the latest compressed dump"
    task :restore, :roles => :db, :only => {:primary => true} do
      prepare_from_yaml
      run "mongorestore #{auth_options} --drop -d #{db_name} #{db_backup_path}/#{db_name}" do |ch, stream, out|
        puts out
      end
    end

    desc "Downloads the compressed database dump and files to this machine"
    task :fetch_dump, :roles => :db, :only => {:primary => true} do
      prepare_from_yaml
      download db_remote_backup, db_local_file, :via => :scp, :recursive => true
      download "#{shared_path}/uploads", "tmp/", :via => :scp, :recursive => true
    end

    def auth_options
      if db_user && db_pass
        "-u #{db_user} -p #{db_pass}"
      end
    end

    # Sets database variables from remote database.yaml
    def prepare_from_yaml
      set(:db_backup_path) { "#{shared_path}/backup/mongodb" }

      set(:db_local_file) { "tmp/" }
      set(:db_user) { db_config[rails_env.to_s]["clients"]["default"]["options"]["user"] }
      set(:db_pass) { db_config[rails_env.to_s]["clients"]["default"]["options"]["password"] }
      set(:db_host) { db_config[rails_env.to_s]["clients"]["default"]["hosts"][0].split(':')[0] }
      set(:db_port) { db_config[rails_env.to_s]["clients"]["default"]["hosts"][0].split(':')[1] }
      set(:db_name) { db_config[rails_env.to_s]["clients"]["default"]["database"] }

      set(:db_remote_backup) { "#{db_backup_path}/#{db_name}" }
    end

    def db_config
      @db_config ||= fetch_db_config
    end

    def fetch_db_config
      require 'yaml'
      file = capture "cat #{shared_path}/config/mongoid.yml"
      YAML.load(file)
    end
  end

  after 'deploy:setup', "mongoid:setup"
  before "deploy:assets:precompile", "mongoid:create_symlink"
end

