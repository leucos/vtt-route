# encoding: UTF-8
#

# This controller displays the state for the user registration
# It will print out what information is missing
# to accept it
class Registrations < Controller
  ELEMENTS = { :certificate => "certificat médical",
               :authorization => "autorisation parentale",
               :payment => "règlement" }

  helper :form_helper, :user

  before_all do
    redirect_referrer unless logged_in? and user.profile
  end

  def index
    @subtitle = "Etat de votre inscription"

    @pieces = Array.new

    [ :certificate, :authorization, :payment ].each do |p|
      @pieces << { :type => p, :name => ELEMENTS[p], :status => user.profile.send(p.to_s + "_received?") } if (user.profile.send(p.to_s + "_required?"))
    end
  end
end
