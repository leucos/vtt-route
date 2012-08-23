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
        flash[:error] = "Erreur d'identifiant ou de mot de passe"
        #redirect r(:login)
      end

      if (user.profile)
        redirect Registrations.r(:index)
      else
        redirect Profiles.r(:index)
      end        
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

    #MailWorker::Confirmer.perform_async
    send_confirmation_email(u.email, u.confirmation_key)
    event(:email_sent, :type => :confirm)

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

      #MailWorker::Confirmer.perform_async(u.email, "#{VttRoute.options.myurl}/#{Users.r(:confirm, u.confirmation_key)}")
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

    # Let's check if passwords match first
    if request.params['pass1'] != request.params['pass2']
      flash[:error] = 'Les mots de passe ne correspondent pas.'
      redirect_referrer
    end

    if request.params['pass1'] == '' or request.params['pass1'].nil?
      flash[:error] = 'Le mot de passe ne peut pas être vide.'
      redirect_referrer
    end

    data[:password] = request.params['pass1']

    begin
      u.update(data)
    rescue NoMethodError => e
      flash[:error] = "Ooops, quelque chose s'est très mal passé... J'ai prévenu le responsable."
      event(:edge_case, :controller => "Users#check_and_save_user", :type => :failed_nil_user) 
      redirect_referrer
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
    MailUtils::Confirmer.perform_async(email, "#{VttRoute.options.myurl}/#{Users.r(:confirm, key)}")
  end

  def send_reset_email(email, key)
    MailUtils::Reseter.perform_async(email, "#{VttRoute.options.myurl}/#{r(:lost_password, key)}")
  end

end
