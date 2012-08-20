require 'daemons'

Daemons.run('bin/fnordmetric.rb', 
            :app_name => 'fnordmetrics',
            :ARGV => [ ARGV[0] || 'stop', '--', ARGV[1] || 4568 ],
            :log_dir => '../log/',
            :log_output => true,
            :dir_mode => :script,
            :dir => '../tmp/pids/')


