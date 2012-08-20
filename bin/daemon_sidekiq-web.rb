require 'daemons'

Daemons.run('bin/sidekiq-web.rb', 
            :app_name => 'sidekiq-web',
            :ARGV => [ ARGV[0], '--', ARGV[1] ],
            :log_dir => '../log/',
            :log_output => true,
            :dir_mode => :script,
            :dir => '../tmp/pids/')


