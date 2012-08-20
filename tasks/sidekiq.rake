require './config/sidekiq'

namespace :sidekiq do
  # Workers
  desc "Starts sidekiq workers"
  task "workers:start" do
    puts "Starting sidekiq workers..."
    system("bundle exec ruby bin/daemon_sidekiq-workers.rb start")
  end
  desc "Stops sidekiq workers"
  task "workers:stop" do
    system("bundle exec ruby bin/daemon_sidekiq-workers.rb stop")
  end

  # Web
  desc "Starts sidekiq web"
  task "web:start" do
    puts "Starting sidekiq web interface on port #{SIDEKIQ_WEB_PORT}..."
    system("bundle exec ruby bin/daemon_sidekiq-web.rb start #{SIDEKIQ_WEB_PORT}")
  end
  desc "Stops sidekiq web"
  task "web:stop" do
    system("bundle exec ruby bin/daemon_sidekiq-web.rb stop")
  end
end
