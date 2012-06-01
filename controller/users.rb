# encoding: UTF-8
#

class Users < Controller
  helper :form_helper, :user

  def index
    redirect r(:login)
  end

  def create
    @title = 'Inscription'
    @subtitle = 'S\'inscrire'
  end

  def login
    @title = "Connexion"
    redirect_referer if logged_in?
    return unless request.post?
    user_login(request.subset(:email, :password))
    redirect Profiles.r(:index)
  end

  def logout
    flash[:success] = "Logged out"
    user_logout
  end

  def save
    user = User.new

    data = {}
    data[:email] = request.params['email']

    # Let's check if passwords match first
    # TODO: form should be pre-filled again
    if request.params['pass1'] != request.params['pass2']
      flash[:error] = 'Les mots de passe ne correspondent pas'
    else
      # Password match, let's use one of them if not nil
      data[:password] = request.params['pass1'] unless request.params['pass1'].nil?
    end

    begin
      user.update(data)
    rescue Sequel::ValidationFailed => e
      Ramaze::Log.info(e.inspect)
      e.errors.each do |i|
        Ramaze::Log.info("error with field #{i[0]}")
        flash[:error] = e.message
        redirect_referrer
      end
    end

    send_confirmation_email(user.email, user.confirmation_key)
    flash[:success] = 'Utilisateur créé'
    @subtitle = 'Email de vérification envoyé'
    @title = 'Inscription'
  end

  def confirm(key)
    u = User[:confirmation_key => key, :confirmed => false]
    @title = 'Inscriptions'

    if u.nil?
      @subtitle = 'Compte inexistant'
      redirect(self.r(:index))
    else
      u.confirmed = true
      u.save

      @subtitle = 'Votre compte est validé'
    end
  end

  private

  def send_confirmation_email(email, key)
    body =<<EOF
Bonjour,

  Afin de valider votre inscription au challenge VTT-Route, merci de bien
vouloir suivre ce lien :
  http://#{MYURL}#/{r(:confirm,key)}

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
