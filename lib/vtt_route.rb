require 'sidekiq'

# Class holding some application settings
# and facts (e.g. version, applicaiton URL)
#
# See config/settings.rb where 
# This file is just reopening the class to add
# version ,information
class VttRoute
  Version =`git describe --always --tag`.chomp
end

