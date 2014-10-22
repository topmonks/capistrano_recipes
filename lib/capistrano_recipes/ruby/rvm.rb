require 'capistrano_recipes/utils'

# RVM (Ruby Version Manager)-related tasks
# @deprecated This tasks are untested and most likely don't work
Capistrano::Configuration.instance.load do
  namespace :rvm do
    desc "Installs rvm on target machine"
    task :install_rvm do
      sudo_commands do
        run "curl -L https://get.rvm.io | #{sudo} bash -s stable --ruby"
      end
    end

    desc "Cretaes rvm gemset (must be run after +rvm:install_ruby+)"
    task :create_gemset do
      ruby, gemset = rvm_ruby_string.to_s.strip.split /@/
      if %w( release_path default ).include? "#{ruby}"
        raise "gemset can not be created when using :rvm_ruby_string => :#{ruby}"
      else
        if gemset
          sudo_commands do
            run "#{File.join(rvm_bin_path, "rvm")} #{ruby} do rvm gemset create #{gemset}"
          end
        end
      end
    end
  end
end
