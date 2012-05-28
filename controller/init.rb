# Define a subclass of Ramaze::Controller holding your defaults for all controllers. Note 
# that these changes can be overwritten in sub controllers by simply calling the method 
# but with a different value.

class Controller < Ramaze::Controller
  layout :default
  helper :xhtml, :flash
  engine :etanni
end

require 'pony'

require __DIR__('main')
require __DIR__('users')
require __DIR__('participants')

