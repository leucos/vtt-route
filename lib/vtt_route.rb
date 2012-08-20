require 'sidekiq'

class VttRoute
  Version =`git describe --always --tag`.chomp
end

