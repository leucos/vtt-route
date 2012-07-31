# encoding: UTF-8
#

# This controller displays the state for the user registration
# It will print out what information is missing
# to accept it
class Registrations < Controller
  helper :form_helper, :user

  def index
    @subtitle = "Etat de votre inscription"
  end
end
