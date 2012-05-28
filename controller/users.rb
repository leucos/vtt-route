# encoding: UTF-8
#

class Users < Controller
  layout :main
  helper :form_helper

  FIELD_NAMES = { :email => "Email", 
                  :name  => "Nom",
                  :surname => "Prénom",
                  :gender  => "Sexe",
                  :address1 => "Adresse",
                  :address2 => "Complément d'adresse",
                  :zip => "Code Postal",
                  :city => "Ville",
                  :country => "Pays",
                  :phone => "Téléphone",
                  :org => "Club ou entreprise", 
                  :birth => "Date de naissance", 
                  :licence => "Numéro de licence",
                  :event => "Epreuve", 
                  :pass1 => "Mots de passe",
                  :pass2 => "Mots de passe",
                  :password => "Mots de passe",
                  :peer => "Coéquipier" }


  def index
    @title = 'Espace participants'
    @subtitle = ''
  end

  def create
    @title = 'Inscription'
    @subtitle = 'S\'inscrire'

#    flash[:form_data] ||= {}
#    flash[:error] = {}

    # Quite ugly, but we don't want to use 'if's in view
    FIELD_NAMES.each_key do |f|
      Ramaze::Log.info("adding key %s" % f)
    end

  end

  def save
    user = User.new

    data = request.subset(:email, :name, :surname, :gender,
                          :address1, :address2, :zip, :city, :country,
                          :phone, :org, :licence, :event, :peer)

    id = request.params['id']

    if !id.nil? and !id.empty?
      # This is an update
      Ramaze::Log.info("trying to update user ##{id}")
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
      Ramaze::Log.info("trying to create user")
      user = User.new
      operation = :create

    end

    # Let's check if passwords match first
    # TODO: form should be pre-filled again
    if request.params['pass1'] != request.params['pass2']
      error_for :password, 'Les mots de passe ne correspondent pas'
    else
      # Password match, let's use one of them if not nil
      data[:password] = request.params['pass1'] unless request.params['pass1'].nil?
    end

    # Now let's update the User instance
    # Since many things can fail, we enclose this in a rescue block
    begin
      date_str = "%s-%s-%s" % [ request.params['dob-year'],
                                request.params['dob-month'],
                                request.params['dob-day'] ]
      data[:birth] = Date.parse(date_str)
    rescue
      # Let Sequel handle this and report back
      data[:birth] = nil
    end

    begin
      user.raise_on_typecast_failure = false
      user.update(data)
    rescue Sequel::ValidationFailed => e

      Ramaze::Log.info(e.inspect)
      e.errors.each do |i|
        Ramaze::Log.info("missing field #{i[0]}")
        error_for i[0], "%s : %s" % [ FIELD_NAMES[i[0]], i[1][0] ]
      end
    end

    if has_errors?
      # An error occured, so let's save form data
      # so the user doesn't have to retype everything
      #flash[:form_data] = data
      ##['dob-day', 'dob-month', 'dob-year'].each do |d|
      ##  flash[:form_data][d] = request.params[d]
      ##end

      bulk_data data
      prepare_flash
      redirect_referrer
    end

    case operation
    when :update
      flash[:success] = 'Vos informations ont été mises à jour'
      redirect_referrer
    when :create
      send_confirmation_email(user.email, user.confirmation_key)
      flash[:success] = 'Utilisateur créé'
      @subtitle = 'Email de vérification envoyé'
      @title = 'Inscription'

      render_view(:confirm)
    end
  end

  def confirm(key)
    u = User[:confirmation_key => key]

    if u.nil?
      @subtitle = 'Compte inexistant'
      redirect(self.r(:index))
    else
      u.confirmed = true
      u.save
      @subtitle = 'Votre compte est validé'
      render_view(:welcome)
    end
  end

  private

  # Tries to update user and return an error array is something failed
  def update_user(user)

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

  Ramaze::Log.info("sending validation email to #{email}");
  Pony.mail(:to => email,
            :from => 'info@challengevttroute.fr',
            :subject => 'Inscription au challenge VTT-Route',
            :body => body,
            :via => :sendmail)
end


  def send_welcome_email(user)

  end

end
