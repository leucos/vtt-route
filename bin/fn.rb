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

# Edge cases
#   numeric (delta) gauge, 1-day tick
gauge :edge_cases_per_day, :tick => 1.day.to_i, :title => "Daily edge cases"
gauge :edge_cases_per_hour, :tick => 1.hour.to_i, :title => "Hourly edge cases"
gauge :failed_no_email_per_day, :tick => 1.day.to_i, :title => "Daily 'no email' cases"
gauge :failed_not_confirmed_per_day, :tick => 1.day.to_i, :title => "Daily 'not confirmed' cases"
gauge :failed_invalid_key_per_day, :tick => 1.day.to_i, :title => "Daily 'invalid key' cases"

event(:edge_case) do 
  # add the value of my_set_age to the avg_age_per_session gauge if session_key 
  # hasn't been seen in this tick yet
  incr :edge_cases_per_day
  incr :edge_cases_per_hour

  incr :failed_no_email_per_day if data[:type] == 'failed_no_email'
  incr :failed_not_confirmed_per_day if data[:type] == 'failed_not_confirmed'
  incr :failed_invalid_key_per_day if data[:type] == 'failed_invalid_key'
end

# Email traffic
#   numeric (delta) gauge, 1-day tick
gauge :email_sent_per_day, :tick => 1.day.to_i, :title => "Daily emails"
gauge :email_sent_per_hour, :tick => 1.hour.to_i, :title => "Hourly emails"
gauge :administrative_email_sent_per_day, :tick => 1.day.to_i, :title => "Daily admin email sent"
gauge :password_reset_email_sent_per_day, :tick => 1.day.to_i, :title => "Daily password reset email sent"
gauge :subscription_email_sent_per_day, :tick => 1.day.to_i, :title => "Daily subscription email sent"

event(:email_sent) do 
  # add the value of my_set_age to the avg_age_per_session gauge if session_key 
  # hasn't been seen in this tick yet
  incr :email_sent_per_day
  incr :email_sent_per_hour

  incr :administrative_email_sent_per_day if data[:type] == 'administrative'
  incr :subscription_email_sent_per_day if data[:type] == 'subscription'
  incr :password_reset_email_sent_per_day if data[:type] == 'password_reset'
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

widget 'Email', {
  :title => "Email sent per day",
  :type => :timeline,
  :plot_style => :areaspline,
  :gauges => [ :administrative_email_sent_per_day, :subscription_email_sent_per_day, :password_reset_email_sent_per_day ],
  :include_current => true,
  :autoupdate => 2
}

widget 'Edge cases', {
  :title => "Edge cases per day",
  :type => :timeline,
  :plot_style => :areaspline,
  :gauges => :edge_cases_per_day,
  :include_current => true,
  :autoupdate => 2
}

widget 'Edge cases', {
  :title => "Edge cases per hour",
  :type => :timeline,
  :plot_style => :areaspline,
  :gauges => :edge_cases_per_hour,
  :include_current => true,
  :autoupdate => 2
}

widget 'Edge cases', {
  :title => "Edge cases distribution per day",
  :type => :timeline,
  :plot_style => :areaspline,
  :gauges =>  [:failed_no_email_per_day, :failed_not_confirmed_per_day, :failed_invalid_key_per_day],
  :include_current => true,
  :autoupdate => 2
}

end




FnordMetric.standalone

