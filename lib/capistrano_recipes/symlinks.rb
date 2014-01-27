require 'capistrano_recipes/utils'

Capistrano::Configuration.instance.load do

  _cset(:target_dir) { "#{shared_path}/config" }

  # TODO
  YML_EXAMPLES = %w{application credit_card_info it_ticket_companies}

  namespace :symlinks do
    desc "Create"
    task :setup, :roles => :app, :except => {:no_release => true} do
      run "mkdir -p #{shared_path}/uploads"
      YML_EXAMPLES.each do |file|
        next if remote_file_exists?(target_dir + "/#{file}.yml")
        cp_file(File.expand_path("../../#{file}.example.yml", __FILE__), target_dir + "/#{file}.yml")
      end
    end

    task :create_symlink, roles: :app do
      YML_EXAMPLES.each do |file|
        run "ln -nfs #{shared_path}/config/#{file}.yml #{release_path}/config/#{file}.yml"
      end
      run "rm -rf #{release_path}/uploads} && ln -nfs #{shared_path}/uploads #{release_path}/uploads"
    end
  end

  after 'deploy:setup', "symlinks:setup"
  before "deploy:assets:precompile", "symlinks:create_symlink"

end