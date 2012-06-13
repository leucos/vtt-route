# encoding: UTF-8
#
class User < Sequel::Model
  plugin :validation_helpers
  one_to_one :profile

  include BCrypt

  def validate
    super
    validates_unique :email, :message => "Cette adresse email est déjà utilisée." #" Voulez vous vous <a href='#{Users.r(:login)}'>connecter</a>?"
    validates_presence :password_hash, :message => 'Ce champ doit être renseigné'
  end

  def before_create
    self.confirmation_key = SecureRandom.hex(16)
    self.created_at ||= Time.now
    super
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

    if !user.nil? and user.password == creds['password']
      Ramaze::Log.info("Login success")
      return user
    else
      Ramaze::Log.info("Login failure : wrong password")
      return false
    end
  end

end
