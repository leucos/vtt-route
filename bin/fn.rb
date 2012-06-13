#!/usr/bin/env ruby
#
require 'fnordmetric'

FnordMetric.namespace :vttroute do

# Logins
#   numeric (delta) gauge, 1-day tick
gauge :logins_per_day, :tick => 1.day.to_i, :title => "Daily logins"
gauge :logins_per_hour, :tick => 1.hour.to_i, :title => "Hourly logins"

event(:login) do
  incr :logins_per_day
  incr :logins_per_hour
end

# Logins failed
#   numeric (delta) gauge, 1-day tick
gauge :logins_failed_per_day, :tick => 1.day.to_i, :title => "Daily failed logins"
gauge :logins_failed_per_hour, :tick => 1.hour.to_i, :title => "Hourly failed logins"

event(:login_failed) do
  incr :logins_failed_per_day
  incr :logins_failed_per_hour
end

# Logouts
#   numeric (delta) gauge, 1-day tick
gauge :logouts_per_day, :tick => 1.day.to_i, :title => "Daily logouts"
gauge :logouts_per_hour, :tick => 1.hour.to_i, :title => "Hourly logouts"

event(:logout) do
  incr :logouts_per_day
  incr :logouts_per_hour
end

# Mean year of birth
  # numeric (delta) gauge, increments uniquely by session_key, returns average
gauge :avg_age_per_session, 
  :tick => 1.day.to_i, 
  :unique => true,
  :average => true,
  :title => "Avg. User Yob"

  # on every event like { "_type": "_my_set_age", "my_age_field": "23" }
event(:user_yob) do 
  # add the value of my_set_age to the avg_age_per_session gauge if session_key 
  # hasn't been seen in this tick yet
  incr :avg_age_per_session, data[:year] 
end

# 404 sent
#   numeric (delta) gauge, 1-day/hour tick
gauge :status_404_per_day, :tick => 1.day.to_i, :title => "Daily 404s"
gauge :status_404_per_hour, :tick => 1.hour.to_i, :title => "Hourly 404s"

event(:status_404) do
  incr :status_404_per_day
  incr :status_404_per_hour
end


# All events
#   numeric (progressive) gauge, 1-day tick
gauge :events_total, :tick => 1.day.to_i, :progressive => true, :title => "Daily Events (total)"

# on _every_ event
event :"*" do
  incr :events_total 
end

# Unique pageviews
#   numeric (delta) gauge, increments uniquely by session_key
gauge :pageviews_daily_unique, :tick => 1.day.to_i, :unique => true, :title => "Unique Visits (Daily)"

#   three-dimensional (delta) gauge (time->key->value)
gauge :pageviews_per_url_daily, :tick => 1.day.to_i, :title => "Daily Pageviews per URL", :three_dimensional => true

event :_pageview do
  # increment the daily_uniques gauge by 1 if session_key hasn't been seen
  # in this tick yet
  incr :pageviews_daily_unique
  # increment the pageviews_per_url_daily gauge by 1 where key = 'page2'
  incr_field :pageviews_per_url_daily, data[:url]
end

#
# WIDGETS
#

widget 'Overview', {
  :title => "Events per day",
  :type => :timeline,
  :plot_style => :areaspline,
  :gauges => :events_total,
  :include_current => true,
  :autoupdate => 10
}

widget 'Overview', {
  :title => "Visits per day",
  :type => :timeline,
  :plot_style => :areaspline,  
  :gauges => :pageviews_daily_unique,
  :include_current => true,
  :autoupdate => 10
}

widget 'Users', {
  :title => "Connection activity per day",
  :type => :timeline,
  :plot_style => :areaspline,
  :gauges => [ :logins_per_day, :logins_failed_per_day, :logouts_per_day ],
  :include_current => true,
  :autoupdate => 2
}

widget 'Users', {
  :title => "Connection activity per hour",
  :type => :timeline,
  :plot_style => :areaspline,
  :gauges => [ :logins_per_hour, :logins_failed_per_hour, :logouts_per_hour ],
  :include_current => true,
  :autoupdate => 2
}

widget 'Users', {
  :title => "Averaged visitor's year of birth",
  :type => :numbers,
  :gauges => :avg_age_per_session,
  :include_current => true,
  :autoupdate => 10
}

widget 'Pages', {
  :title => "Top Pages",
  :type => :toplist,
  :autoupdate => 20,
  :gauges => [ :pageviews_per_url_daily ]
}

widget 'Pages', {
  :title => "404 per hour",
  :type => :timeline,
  :plot_style => :areaspline,
  :autoupdate => 20,  
  :include_current => true,
  :gauges => :status_404_per_hour
}

widget 'Pages', {
  :title => "404 per day",
  :type => :timeline,
  :plot_style => :areaspline,
  :autoupdate => 20,
  :include_current => true,
  :gauges => :status_404_per_day
}
end

FnordMetric.standalone

