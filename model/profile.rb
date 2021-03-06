# encoding: UTF-8
#
class Profile < Sequel::Model
  plugin :validation_helpers
  plugin :composition

  include BCrypt

  def before_create
    self.created_at ||= Time.now
    super
  end

  def before_save
    self.updated_at ||= Time.now
    super
  end

  def validate
    super
    validates_presence [:name, :surname, :address1, :zip, :city, :country,
                        :phone, :gender, :birth, :emergency_contact ],
                        :message => 'Ce champ doit être renseigné'
    validates_exact_length 5, :zip, :message => 'Ce code postal est invalide'
    errors.add(:birth, "Vous n'avez pas l'âge minimum requis") if age_at_event < 15
  end

  def age_at_event
    # We might not have all the fields populated here
    # since we're called from validate
    return 0 unless self.birth
#    EVENT_DATE.year - self.birth.year - (self.birth.change(:year => EVENT_DATE.year) > EVENT_DATE ? 1 : 0)
    EVENT_DATE.year - self.birth.year
  end

  def certificate_required?
    self.federation == "Non licencié" || self.licence.blank?
  end

  def authorization_required?
    age_at_event < 18
  end

  def payment_required?
    true
  end

  def certificate_received?
    self.certificate_received
  end

  def authorization_received?
    self.authorization_received
  end

  def payment_received?
    self.payment_received
  end

  def missing
    elements = {  :certificate    => { :name => "certificat médical", 
                                       :description => "Sans licence sportive, vous devez fournir un certificat médical." },
                  :authorization  => { :name => "autorisation parentale",
                                       :description => "Vous êtes mineur, une autorisation parentale est requise." },
                  :payment        => { :name => "règlement",
                                       :description => "Le règlement doit nous parvenir à l'avance." },
                  :team           => { :name => "équipe",
                                       :description => "Vous n'êtes dans aucune équipe" }

                }

    pieces = Array.new

    [ :certificate, :authorization, :payment ].each do |p|
      pieces << {  :type => p, 
                    :name => elements[p][:name], 
                    :description => elements[p][:description],
                    :status => self.send(p.to_s + "_received?") } if (self.send(p.to_s + "_required?"))
    end
    pieces
  end
end

