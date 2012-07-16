namespace :server do
  desc "Starts thin server"
  task :start do
    system("thin -C #{RAMAZE_ROOT}/config/thin.yml start -e live")
  end
  desc "Stops thin servers"
  task :stop do
    system("thin -C #{RAMAZE_ROOT}/config/thin.yml stop -e live")
  end
end
