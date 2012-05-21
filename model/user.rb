# encoding: UTF-8
#
class User < Sequel::Model
  plugin :validation_helpers
  plugin :composition

  include BCrypt

  one_to_many :partner, :key => :peer, :class => self

  def validate
    validates_unique :email, :message => 'Cette adresse email est déjà utilisée'
    validates_presence [:name, :surname, :address1, :zip, :city, 
                        :email, :password_hash, :gender, :birth, :event ],
                        :message => 'Ce champ doit être renseigné'
    validates_exact_length 5, :zip, :message => 'Ce code postal est invalide'
  end

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

end
