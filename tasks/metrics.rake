PIDFILE = "#{RAMAZE_ROOT}/tmp/pids/fnordmetrics"
  
  namespace :metrics do
  desc "Starts Fnordmetrics"
  task :start do
    system("#{RAMAZE_ROOT}/bin/fn.rb run > #{RAMAZE_ROOT}/log/fnordmetric.log 2>&1 & echo $! > #{PIDFILE}")
  end

  desc "Stops Fnordmetrics"
  task :stop do
    open("#{PIDFILE}").each do |l|
      `kill -TERM #{l.chomp}`
    end
    File.delete PIDFILE
  end
end
