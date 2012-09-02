require 'daemons'

#bundle exec sidekiq -vq high,5 default -r ./lib/mail_worker.rb

path=`bundle exec which sidekiq`.chomp

Daemons.run(path, 
            :app_name => 'sidekiq-workers',
            :ARGV => [ ARGV[0], '--', '-v', '-q', 'high,5', 'default', '-r', "#{Dir.pwd}/lib/mail_utils.rb" ],
            :log_dir => './log/',
            :log_output => true,
            :dir_mode => :normal,
            :dir => './tmp/pids/')


