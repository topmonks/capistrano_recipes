require 'capistrano_recipes/utils'

Capistrano::Configuration.instance.load do

namespace :redis do

  desc "Install redis"
  task :install do
    [
      "cd /tmp && wget http://download.redis.io/redis-stable.tar.gz",
      "cd /tmp && tar xvzf redis-stable.tar.gz",
      "cd /tmp/redis-stable && make"
    ].each {|cmd| run cmd}

    sudo_commands do
      ["#{sudo} cp /tmp/redis-stable/src/redis-benchmark /usr/bin/",
        "#{sudo} cp /tmp/redis-stable/src/redis-cli /usr/bin/",
        "#{sudo} cp /tmp/redis-stable/src/redis-server /usr/bin/",
        "#{sudo} cp /tmp/redis-stable/redis.conf /etc/",
        "#{sudo} sed -i 's/daemonize no/daemonize yes/' /etc/redis.conf",
        "#{sudo} sed -i 's@^pidfile /var/run/redis.pid@pidfile /tmp/redis.pid@' /etc/redis.conf"
      ].each {|cmd| run cmd}
    end
  end

  desc "Start the Redis server"
  task :start do
    run "redis-server /etc/redis.conf"
  end

  desc "Stop the Redis server"
  task :stop do
    run 'echo "SHUTDOWN" | nc localhost 6379'
  end

end

after "deploy:setup", "redis:install"
end