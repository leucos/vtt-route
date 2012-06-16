# encoding: UTF-8
#

class Users < Controller
  helper :form_helper, :user, :gravatar, :fnordmetric

  def index
    redirect r(:login)
  end

  def create
    @title = 'Inscription'
    @subtitle = 'S\'inscrire'
  end

  def login
    @title = "Connexion"
    @subtitle = 'Se connecter'

    redirect_referer if logged_in?
    return unless request.post?

    if VttRoute.options.state == :preinscriptions
      @subtitle = "Connexion non disponible pour l'instant"
    else
      times :credential_lookup do
        user_login(request.subset(:email, :password))
      end

      if logged_in?
        if (user.profile)
          set_name("#{user.profile.name} #{user.profile.surname}")
          event(:user_yob, :year => user.profile.birth.year - 1000)
        else
          set_name(user.email)
        end
        set_picture(gravatar(user.email.to_s)) if user.email

        event(:login)
      else
        # Login failed
        Ramaze::Log.debug("OMG login failed")
        event(:login_failed)
        response.status = 302
        response.headers['Location'] = r(:login)
        #redirect r(:login)
      end


      redirect Profiles.r(:index)
    end
  end
  clock :login, :performance

  def logout
    flash[:success] = "Déconnecté"
    event(:logout)
    user_logout
    session.resid!
  end

  def save
    u = User.new

    check_and_save_user(u, request.params['email'])

    send_confirmation_email(u.email, u.confirmation_key)
    flash[:success] = 'Utilisateur créé'
    @subtitle = 'Email de vérification envoyé'
    @title = 'Inscription'
  end

  def confirm(key)
    u = User[:confirmation_key => key, :confirmed => false]
    @title = 'Inscriptions'

    if u.nil?
      @subtitle = 'Compte inexistant'
      flash[:error] = "Ce numéro de confirmation n'existe pas"
      
      redirect MainController.r(:/)
    else
      u.confirmation_key = nil
      u.confirmed = true
      u.save

      @subtitle = 'Votre compte est validé'
    end
  end

  def ask_reset
    # Let's sleep for a while so we don't get brute forced
    # This doesn't help much for // requests though...
    sleep 3*rand

    u = User[:email => request.params['email']]
    # No email, this user doesn't exist
    if u.nil? 
      flash[:error] = "Désolé, cet email n'existe pas"
      event(:edge_case, :controller => "Users#lostpassword", :type => :failed_no_email) 
      redirect_referrer
    end
    # Account not confirmed yet
    if !u.confirmed
      flash[:error] = "Désolé, vous n'avez pas confirmé votre compte. Veuillez suivre les instructions reçues par email"
      event(:edge_case, :controller => "Users#lostpassword", :type => :failed_not_confirmed) 

      send_confirmation_email(u.email, u.confirmation_key)
      redirect_referrer
    end

    # Now we can generate a request
    u.set_confirmation_key
    u.save
    send_reset_email(u.email, u.confirmation_key)
    flash[:success] = "Veuillez vérifier votre messagerie pour réinitialiser votre mot de passe"
    redirect MainController.r(:/)
  end

  def lost_password(key)
    # someone followed the reset link in the email
    u = User[:confirmation_key => key]

    # someone followed the reset link in the email
    @title = 'Réinitialisation du mot de passe'

    if u.nil?
      @subtitle = 'Compte inexistant'
      flash[:error] = "Ce numéro de validation n'existe pas"
      event(:edge_case, :controller => "Users#lostpassword", :type => :failed_invalid_key) 

      redirect MainController.r(:/)
    end

    @subtitle = 'Entrez votre nouveau mot de passe'
    @key = key
  end

  def do_reset
    # This is a post : new password
    u = User[:confirmation_key => request.params['key']]

    check_and_save_user(u)
    flash[:success] = "Modification effectuée. Vous pouvez vous connecter."
    redirect r(:login)
  end

  private

  def check_and_save_user(u, email=nil)
    data = {}
    data[:email] = email if email
    p u.inspect

    # Let's check if passwords match first
    # TODO: form should be pre-filled again
    if request.params['pass1'] != request.params['pass2']
      flash[:error] = 'Les mots de passe ne correspondent pas'
    else
      # Password match, let's use one of them if not nil
      data[:password] = request.params['pass1'] unless request.params['pass1'].nil?
    end

    begin
      u.update(data)
    rescue Sequel::ValidationFailed => e
      Ramaze::Log.info(e.inspect)
      e.errors.each do |i|
        Ramaze::Log.info("error with field #{i[0]}")
        flash[:error] = e.message
        redirect_referrer
      end
    end
  end

  def send_confirmation_email(email, key)
    body =<<EOF
Bonjour,

Afin de valider votre inscription au challenge VTT-Route, merci de bien
vouloir suivre ce lien :

#{VttRoute.options.myurl}/#{r(:confirm, key)}

Vous pourrez ensuite inviter un coéquipier si vous participez à un 
challenge par équipes.

En cas de difficultés, vous pouvez nous contacter en cliquant sur 'Répondre'
ou en écrivant à : info@challengevttroute.fr

Cordialement,

L'équipe du challenge VTT-Route
--
Challenge VTT-Route
info@challengevttroute.fr
EOF

  Ramaze::Log.info("sending validation email to #{email}");
  event(:email_sent, :type => :subscription)
  Pony.mail(:to => email,
            :from => 'info@challengevttroute.fr',
            :subject => 'Inscription au challenge VTT-Route',
            :body => body,
            :via => :sendmail)

  event(:email_sent, :type => :administrative)
  Pony.mail(:to => VttRoute.options.admin_email,
            :from => 'info@challengevttroute.fr',
            :subject => '[vtt-route] Inscription reçue',
            :body => "L'utilisateur #{email} s'est inscrit.",
            :via => :sendmail)
  end

  def send_reset_email(email, key)
    body =<<EOF
Bonjour,

Apparemment, vous avez perdu votre mot de passe. Ne vous inquiétez
pas, ça nous arrive à tous. Vous pouvez le ré-initialiser en vous
rendant à cette adresse :

#{VttRoute.options.myurl}/#{r(:lost_password, key)}

Si vous n'avez pas perdu votre mot de passe, quelqu'un doit faire une
mauvaise blague. Dans ce cas, vous pouvez ignorer ce message.

En cas de difficultés, vous pouvez nous contacter en cliquant sur
'Répondre' ou en écrivant à : info@challengevttroute.fr

Cordialement,

L'équipe du challenge VTT-Route
--
Challenge VTT-Route
info@challengevttroute.fr
EOF

  Ramaze::Log.info("sending reset email to #{email}");
  event(:email_sent, :type => :password_reset)
  Pony.mail(:to => email,
            :from => 'info@challengevttroute.fr',
            :subject => 'Mot de passe perdu sur challenge VTT-Route',
            :body => body,
            :via => :sendmail)

  event(:email_sent, :type => :administrative)
  Pony.mail(:to => VttRoute.options.admin_email,
            :from => 'info@challengevttroute.fr',
            :subject => '[vtt-route] Reset envoyé',
            :body => "L'utilisateur #{email} a perdu son mot de passe.",
            :via => :sendmail)
  end

  def send_welcome_email(user)

  end

end
