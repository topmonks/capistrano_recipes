require 'capistrano_recipes/utils'

Capistrano::Configuration.instance.load do

  _cset(:ssh_public_key) { "~/.ssh/id_rsa.pub" }

  namespace :check do
    desc "Make sure local git is in sync with remote."
    task :revision, roles: :web do
      unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
        puts "WARNING: HEAD is not the same as origin/#{branch}"
        puts "Run `git push` to sync changes."
        exit
      else
        puts "HEAD is same as origin/#{branch}"
      end
    end

    task :ssh_copy_id do
      key_path = File.expand_path(ssh_public_key)
      if File.exist?(key_path)
        key_string = IO.readlines(key_path)[0].strip
      else
        key_string = ssh_public_key
      end
      run <<-eos
          set -e;
          mkdir -p ~#{user}/.ssh;
          if grep -q -s -F '#{key_string}' ~#{user}/.ssh/authorized_keys ; then
            echo "Key already in authorized keys.";
          else
            touch ~#{user}/.ssh/authorized_keys;
            echo '#{key_string}' | tee -a ~#{user}/.ssh/authorized_keys;
            echo "Added #{key_path} to authorized_keys of #{user}";
          fi;
      eos
    end
  end

  before "deploy", "check:revision"
  before "deploy:migrations", "check:revision"
  before "deploy:cold", "check:revision"
end

