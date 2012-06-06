# encoding: UTF-8
#
class Profile < Sequel::Model
  plugin :validation_helpers
  plugin :composition

  include BCrypt

  
  one_to_many :partner, :key => :peer, :class => self
  many_to_one :user

  def validate
    Ramaze::Log.info('here')
    validates_presence [:name, :surname, :address1, :zip, :city, :country,
                        :phone, :gender, :birth, :event, :emergency_contact ],
                        :message => 'Ce champ doit être renseigné'
    validates_exact_length 5, :zip, :message => 'Ce code postal est invalide'
    #validates_min_length 1, :emergency_contact, :message => 'Ce champ doit être rempli'
    # No Solo for young men
    errors.add(:event, 'Impossible de participer en Solo pour les moins de 17 ans') if birth and birth.year > 1995 
    Ramaze::Log.info('and there')

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
