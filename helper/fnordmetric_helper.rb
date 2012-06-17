# FNordmetric helper
#
# 
require 'fnordmetric'
require 'redis'

module Ramaze
  module Helper
    ##
    # This helper provides a convenience wrapper for sending events to 
    # Fnordmetric.
    #
    # events can be anything, its just an indication that something happened.
    # Fnordmetric can then make some agregates on events received per period.
    #
    # events can also carry arbitrary data, and this helper uses it to send
    # performance data to Fnordmetric, so one can easily measure code execution
    # times.
    # Actually, these times can only be used in a per-request time frame. However
    # future versions of timer methods might cover session lifetimes.
    #
    # events are associated to the Innate session id, and thus are linked to 
    # visitors of your site. this is really usefull since you can, for instance,
    # see how long a controller action took for a particular user.
    #
    # If you want so use a redis server other than the usual localhost:6379, you
    # need to define :fnord_redis_url trait, e.g. :
    #
    #   trait :fnord_redis_url => "redis://redis.example.com:6332"
    #
    # TODO: @example Basic usage...
    # TODO: Implement with_id that uses specific id instead of innate.sid
    module FnordmetricHelper
    
      # @@fnord will hold redis connection
      # @@times holds a stack of timers
      # A timer is an Array holding the event name, a Hash of arguments and a timestamp
      @@fnord = nil
      @@redis = nil
      @@sstack_key = nil

      # We need clock as a class method
      def self.included(base)
        base.extend(ClassMethods)
      end

      ##
      # Creates a fnordmetric instance, holding the Redis connection
      #
      # Do not call this
      def _connect # :nodoc:
        begin
          url = ancestral_trait[:fnord_redis_url]
        rescue
          url = "redis://localhost:6379"
        ensure
          @@fnord = FnordMetric::API.new(:redis_url => url)
          @@redis = Redis.new(:url => url)
          Ramaze::Log.debug("Connected to FnordMetric")
        end
      end

      ##
      # Sends an event to Fnordmetric
      # 
      # This helper method sends an event to Fnordmetric, populating the 
      # :_session field with the current innate sid.
      #
      # @param  [Symbol] evt the name of the event to send to Fnordmetric.
      # @param  [Hash] args a hash of supplemental data to send
      #
      def event(evt, args = {})
        # Let's connect first, it will have to be done anyway
        _connect unless @@fnord
        return unless evt

        evt = { :_type => evt.to_s, :_session => session.sid }

        evt.merge!(args)
        
        Ramaze::Log.debug("Logging Fnordmetric event %s" % evt.inspect)        
        @@fnord.event(evt)
      end

      ##
      # All in one timing function for a block
      #
      # This method will send an event containing the execution time of
      # the passed block.
      #
      # @example Block style usage
      #
      #   times(:performance, :method => :whatever) do
      #     # do stuff to be measured
      #   end
      #
      # @param  [Symbol] event_name the name of the event to send to Fnordmetric.
      # @param  [Hash] args a hash of supplemental data to send
      # @param  [Block] block code to be executed and timed
      #
      def times(event_name, args = {}, &block) 
        push_timer(event_name, args)
        # THINK: may be raise since there is no point in using times without a
        # block
        yield if block_given?
        ensure
          pop_timer
      end

      ##
      # Starts a timer and pushes it to the timers stack
      #
      # @param  [Symbol] event_name the name of the event to send to Fnordmetric.
      # @param  [Hash] args a hash of supplemental data to send
      #
      # @example Push/Pop style usage
      #
      #   push_timer(:performance, :field => :whatever)
      #   # some code
      #   pop_timer
      #
      def push_timer(event_name, args = {})
        @@redis.lpush("#{@@sstack_key}.#{session.sid}", [event_name, args, Time.now.to_f].to_json)

        Ramaze::Log.debug("Timer pushed for %s to %s.%s (stack level is now %s)" % 
          [ event_name, 
            @@sstack_key,
            session.sid,
            @@redis.llen(_key) ])
      end

      ##
      # Pops a timer and sends an event
      #
      # This method pops the last pushed timer and sends an event
      # No arguments are needed, since they were stored by push_timer
      #
      def pop_timer
        len = @@redis.llen(_key)
        if len > 0
          json = @@redis.lpop(_key)

          wat, args, wen = JSON.parse(json)
          Ramaze::Log.debug("Timer popped for %s (stack level is now %s)" % [ wat, len - 1])
          event(wat, args.merge(:time => Time.now-Time.at(wen)))
        else
          Ramaze::Log.error("Unable to pop timer in %s (no event in stack)" % _key)
          raise RuntimeError, "Unable to pop timer in %s (no event in stack)" % _key
        end
      end

      ## 
      # Removes all timers in the stack
      #
      def clear_timers
        Ramaze::Log.debug("Cleared %s timers for %s" % [ @@redis.llen(_key), _key ])
        @@redis.del _key
      end

      ##
      # Sends a _pageview Fnordmetric event
      #
      # This method sends a specific _pageview event  Fnordmetric event
      # This event is treated in a special way by Fnordmetric (see doc).
      # 
      # @param [String] url the URl that is accessed. Defaults to request.env['REQUEST_PATH']
      #
      # @example Logging all page views
      #
      # If all your controllers inherit 'Controller', you can log all page view
      # very easily :
      #
      #   class Controller < Ramaze::Controller
      #     helper :fnordmetric
      #
      #     before_all do
      #       pageview
      #     end
      #
      def pageview(url=request.env['REQUEST_PATH'])
        event(:_pageview, :url => url)
      end

      ##
      # Sets username for the current session
      #
      # This manually sets a user name for the current session. It calls the 
      # specific :_set_name Fnordmetric event
      # This comes handy for user tracking
      #
      # @params [String] name the user name
      #
      def set_name(name)
        event(:_set_name, :name => name)
      end

      ##
      # Sets the picture URL for the user
      #
      # This manually sets a user picture for the current session. It calls the 
      # specific :_set_picture Fnordmetric event.
      # Using this method, you'll be able to have a picture associated to the user
      # in Fnordmetric's user tracking panel 
      # 
      # @param [String] url Picture url
      #
      # @example Using Gravatar to set user picture
      #
      #
      #   class Users < Controller
      #     helper :user, :gravatar, :fnordmetric     
      #     ...
      #     def login
      #       ...
      #       redirect_referrer if logged_in?
      #       user_login(request.subset(:email, :password))
      #       if logged_in?
      #         set_name("#{user.name} #{user.surname}")
      #         set_picture(gravatar(user.email)) if user.email 
      #       end 
      #       ...
      #     end
      #
      def set_picture(url="http://placekitten.com/80/80")
        url = url.to_s if url.class.to_s == 'URI::HTTP'
        event(:_set_picture, :url => url)
      end

      ##
      # Returns the Redis key
      #
      #
      def _key # :nodoc:
        if ! @@sstack_key
          if ancestral_trait[:fnord_helper_namespace]
            @@sstack_key = ancestral_trait[:fnord_helper_namespace]
          else 
            @@sstack_key = Ramaze.options.app.name.to_s
          end
        end
        
        "%s.%s" % [ @@sstack_key, session.sid ]
      end
      ##
      # Holds class methods
      # 
      # This is used to extend the calling controller so these methods are 
      # available at the class level
      # Since helpers are only included, extending the calling controller is 
      # done via the 'included' hook.
      # 
      module ClassMethods
        ##
        # This method replaces the original controller method with a times
        # call that yields the original method.
        # This allows to measure execution time for the method without manually
        # modifying the method itself
        #
        # @param [Symbol] method the method measure
        # @param  [Symbol] event_name the name of the event to send to Fnordmetric.
        # @param  [Hash] args a hash of supplemental data to send
        #
        # @example Measuring execution time for a controller action
        #
        #   class Users < Controller
        #       helper :user, :gravatar, :fnordmetric     
        #     ...
        #     def login
        #       ...
        #       # whatever login does
        #       ...
        #     end
        #     clock :login, :performance, :some_field => "some value"
        #
        def clock(method, event_name, args = {})
          # Let's alias the original controller method to original_name
          original = "original_%s" % method
          alias_method original.to_sym, method.to_sym

          # We merge the method name in the args that will be send in the event
          args.merge!(:method => method)

          # Let's create a shiny new method replacing the old one
          newdef = "def %s(*a, &block) times(:%s, %s) do %s(*a, &block); end; end" % [method, event_name, args, original]
          #newdef = "def %s(*a, &block) push_timer(:%s, %s); yield if block_given?; ensure; pop_timer; end" % [method, event_name, args, original]
          class_eval(newdef)

          Ramaze::Log.debug("Clo(a)cking enabled for %s (renamed as %s)" % [ method, original ])
        end
      end

    end
  end
end
