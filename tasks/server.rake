
namespace :server do
  env = ENV["RACK_ENV"] || "dev"

  desc "Starts thin server"
  task :start do
    system("thin -C #{RAMAZE_ROOT}/config/thin-#{env}.yml start -e #{env}")
  end
  desc "Stops thin servers"
  task :stop do
    system("thin -C #{RAMAZE_ROOT}/config/thin-#{env}.yml stop -e #{env}")
  end
end
