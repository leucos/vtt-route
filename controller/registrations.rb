# encoding: UTF-8
#

# This controller displays the state for the user registration
# It will print out what information is missing
# to accept it
class Registrations < Controller
  ELEMENTS = { :certificate   => { :name => "certificat médical", 
                                   :description => "Sans licence sportive, vous devez fournir un certificat médical." },
               :authorization => { :name => "autorisation parentale",
                                   :description => "Vous êtes mineur, une autorisation parentale est requise." },
               :payment       => { :name => "règlement",
                                   :description => "Le règlement doit nous parvenir à l'avance." }
              }

  helper :form_helper, :user

  before_all do
    redirect_referrer unless logged_in? and user.profile
  end

  def index
    @subtitle = "Etat de votre inscription"

    @pieces = Array.new

    [ :certificate, :authorization, :payment ].each do |p|
      @pieces << {  :type => p, 
                    :name => ELEMENTS[p][:name], 
                    :description => ELEMENTS[p][:description],
                    :status => user.profile.send(p.to_s + "_received?") } if (user.profile.send(p.to_s + "_required?"))
    end
  end
end
