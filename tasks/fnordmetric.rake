require './config/fnordmetric.rb'

namespace :fnordmetric do
  desc "Starts Fnordmetrics"
  task :start do
    puts "Starting fnordmetric daemon on port #{FNORDMETRIC_WEB_PORT}..."
    system("bundle exec ruby bin/daemon_fnordmetric.rb start #{FNORDMETRIC_WEB_PORT}")
  end

  desc "Stops Fnordmetrics"
  task :stop do
    system("bundle exec ruby bin/daemon_fnordmetric.rb stop")
  end
end
