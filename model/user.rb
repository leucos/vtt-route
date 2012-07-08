# encoding: UTF-8
#
class User < Sequel::Model
  plugin :validation_helpers

  # Table relationships
  one_to_one :profile
  one_to_one :team

  include BCrypt

  def validate
    super
    validates_unique :email, :message => "Cette adresse email est déjà utilisée." #" Voulez vous vous <a href='#{Users.r(:login)}'>connecter</a>?"
    validates_presence [ :email, :password_hash ], :message => 'Ce champ doit être renseigné'
  end

  def before_create
    set_confirmation_key
    super
  end

  def set_confirmation_key
    self.confirmation_key = SecureRandom.urlsafe_base64(24)
    self.created_at ||= Time.now
  end

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def self.authenticate(creds)
    Ramaze::Log.info("Login attempt with %s | %s" % [ creds['email'], creds['password'] ] )

    if !creds['email'] or !creds['password']
      Ramaze::Log.info("Login failure : no credentials")
      return false
    end

    user = self[:email => creds['email']]

    if user.nil? 
      Ramaze::Log.info("Login failure : wrong password")
      return false
    end

    if !user.confirmed
      Ramaze::Log.info("Login failure : account not confirmed")
      return false
    end

    if user.password == creds['password']
      # No need to have a confirmation key is user can log
      user.confirmation_key = nil
      Ramaze::Log.info("Login success")
      return user
    end

  end

end
