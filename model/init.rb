# This file is used for loading all your models. Note that you don't have to actually use
# this file. The great thing about Ramaze is that you're free to change it the way you see
# fit.

# Here go your requires for models:

Sequel.extension(:pagination)

require 'bcrypt'
require 'guid'

require __DIR__('user')
