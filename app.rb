# This file contains your application, it requires dependencies and necessary parts of 
# the application.
#
# It will be required from either `config.ru` or `start.rb`
require 'rubygems'
require 'ramaze'

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]

# Some useful requires
require 'sequel'
require 'pony'

EVENT_DATE=Date.new(2012, 10, 28)

# Read some conf
require __DIR__('config/environment')
require __DIR__('config/database')

# Initialize controllers, helpers and models
require __DIR__('model/init')
require __DIR__('helper/init')
require __DIR__('controller/init')
