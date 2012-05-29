# encoding: UTF-8
#
class Profile < Sequel::Model
  plugin :validation_helpers
  plugin :composition

  include BCrypt

  
  one_to_many :partner, :key => :peer, :class => self
  many_to_one :user

  def validate
    validates_presence [:name, :surname, :address1, :zip, :city, :country,
                        :phone, :gender, :birth, :event ],
                        :message => 'Ce champ doit être renseigné'
    validates_exact_length 5, :zip, :message => 'Ce code postal est invalide'
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
