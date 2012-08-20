require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1, :namespace => 'org.chalengevttroute.www.sidekiq' }
end

require 'sidekiq/web'

module Sidekiq
  class Web < Sinatra::Base
    configure do
      set :port, 10101
    end
  end
end

Sidekiq::Web.run!(:port => ARGV[0] || 4567)

