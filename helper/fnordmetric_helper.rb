# FNordmetric helper
#
# Define :fnord_redis_url trait in class where helper is used
# e.g. :   trait :fnord_redis_url => "redis://redis.example.com:6332"
# 
require 'fnordmetric'

module Ramaze
  module Helper
    module FnordmetricHelper
    
      @@fnord = nil

      def _connect
        begin
          url = ancestral_trait[:fnord_redis_url]
        rescue
          url = "redis://localhost:6379"
        ensure
          @@fnord = FnordMetric::API.new(:redis_url => url)
          Ramaze::Log.info("Connected to FnordMetric")
        end
      end

      def event(evt, *args)
        evt = { :_type => evt.to_s, :_session => session.sid }

        args.each do |a|
          evt.merge!(a)
        end

        _connect unless @@fnord
        Ramaze::Log.debug("Logging FM event %s" % evt.inspect)        
        @@fnord.event(evt)
      end

      def set_name(name)
        event(:_set_name, :name => name)
      end

      def set_picture(url)
        url = url.to_s if url.class.to_s == 'URI::HTTP'
        event(:_set_picture, :url => url)
      end

    end
  end
end
