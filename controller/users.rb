# encoding: UTF-8
#

class Users < Controller
  layout :main
  helper :blue_form

  def create
    # TODO: use captcha
    @title = 'Inscription'
    @subtitle = 'S\'inscrire'

    flash[:form_data] ||= {}
    flash[:form_errors] ||= {}
    p request.params
  end

  def save
    user = User.new

    data = request.subset(:email, :name, :surname, :gender,
                          :address1, :address2, :zip, :city, :country,
                          :phone, :org, :licence, :event, :peer)

    p data

    id = request.params['id']

    if !id.nil? and !id.empty?
      # This is an update
      user = User[id]

      # Ensure user tried to edit it's own data
      # If we get here, this means he's tinkering with the post data
      # THINK: Is this enough ? Can user tamper with session data ?
      if user.id != session[:user_id]
        flash[:error] = 'Modification impossible'
        Ramaze::Log.warning('Form edit attempt : %s' % request.params) 
        redirect_referrer
      end

      if user.nil?
        flash[:error] = 'Utilisateur invalide'
        redirect_referrer
      end

      if !user.confirmed
        flash[:error] = 'Vous devez confirmer votre inscription avant'
        redirect_referrer
      end
      operation = :update
    else
      user = User.new
      user.confirmation_key = Guid.new.to_s
      operation = :create

    end

    # Let's check if passwords match first
    if request.params['pass1'] != request.params['pass2']
      flash[:error] = 'Les mots de passe ne correspondent pas'
      redirect_referrer
    end

    # Password match, let's use one of them if not nil
    data[:password] = request.params['pass1'] unless request.params['pass1'].nil?

    #flash[:form_errors] = {}
    #[ :name, :surname, :address1, :zip, :city,
    #  :email, :gender, :birth, :event ].each do |k|
    #  flash[:form_errors][k] = nil
    #  end

    # Now let's update the User instance
    # Since many things can fail, we enclose this in a rescue block
    begin
      data[:birth] = Date.new(request.params['dob-year'].to_i,
                              request.params['dob-month'].to_i,
                              request.params['dob-day'].to_i)
      user.update(data)
    rescue Sequel::ValidationFailed => e
      p e
      e.errors.each do |i|
        Ramaze::Log.info("missing field #{i[0]}")
        flash[:form_errors][i[0]] = :error
      end
      flash[:error] = 'Certains champs obligatoires ne sont pas renseignés'

      redirect_referrer
    end

    case operation
    when :update
      flash[:success] = 'Vos informations ont été mises à jour'
      redirect_referrer
    when :create
      send_confirmation_email(user.email, user.confirmation_key)
      flash[:success] = 'Utilisateur créé'
      render_view(:confirm)
    end
  end

  private

  def create_user

  end

  def send_confirmation_email(email, key)
    body =<<EOF
Bonjour,

  Afin de valider votre inscription au challenge VTT-Route, merci de bien
vouloir suivre ce lien :
  http://inscription.challengevttroute.fr/users/confirm/#{key}

  Vous pourrez ensuite inviter un coéquipier si vous participez à un 
challenge par équipes.

  En cas de difficultés, vous pouvez nous contacter en cliquant sur 'Répondre'
ou en écrivant à : info@challengevttroute.fr

  Cordialement,

L'équipe du challenge VTT-Route
EOF

  Pony.mail(:to => email,
            :from => 'info@challengevttroute.fr',
            :subject => 'Inscription au challenge VTT-Route',
            :body => body,
            :via => :sendmail)
end


def send_welcome_email(user)

end

end
