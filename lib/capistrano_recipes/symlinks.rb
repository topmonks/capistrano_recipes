require 'capistrano_recipes/utils'

Capistrano::Configuration.instance.load do

  _cset(:target_dir) { "#{shared_path}/config" }
  _cset(:link_uploads) { true }
  _cset(:link_uploads_path) { "uploads" } #or public/uploads. On remote server must exist the same path in shared directory!
  _cset(:symlink_yml_examples) { [] } #[database, mongoid, application]  any 'file'.example.yml in config

  namespace :symlinks do
    desc "Create"
    task :setup, :roles => :app, :except => {:no_release => true} do
      run "mkdir -p #{shared_path}/uploads"
      symlink_examples.each do |file|
        next if remote_file_exists?(target_dir + "/#{file}.yml")
        cp_file(File.expand_path("../../#{file}.example.yml", __FILE__), target_dir + "/#{file}.yml")
      end
    end

    task :create_symlink, roles: :app do
      symlink_yml_examples.each do |file|
        run "ln -nfs #{shared_path}/config/#{file}.yml #{release_path}/config/#{file}.yml"
      end
      if link_uploads
        run "rm -rf #{release_path}/#{link_uploads_path}} && ln -nfs #{shared_path}/#{link_uploads_path} #{release_path}/#{link_uploads_path}"
      end
    end
  end

  after 'deploy:setup', "symlinks:setup"
  before "deploy:assets:precompile", "symlinks:create_symlink"
end