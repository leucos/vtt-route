# encoding: UTF-8
#
class User < Sequel::Model
  plugin :validation_helpers
  plugin :composition

  include BCrypt

  one_to_many :partner, :key => :peer, :class => self

  def validate
    validates_unique :email, :message => 'Cette adresse email est déjà utilisée'
    validates_presence [:name, :surname, :address1, :zip, :city, :country,
                        :email, :password_hash, :gender, :birth, :event ],
                        :message => 'Ce champ doit être renseigné'
    validates_exact_length 5, :zip, :message => 'Ce code postal est invalide'
  end

  def before_create
    self.confirmation_key = Guid.new.to_s
  end

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def age_at_event
    (EVENT_DATE - self.birth).to_f/365
  end

  def needs_certificate?
    ! (self.federation && self.licence)
  end

  def needs_authorization?
    age_at_event < 18
  end

end
