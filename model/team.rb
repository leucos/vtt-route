# encoding: UTF-8
#
class Team < Sequel::Model
  plugin :validation_helpers

  many_to_one :vtt, :class => :User
  many_to_one :route, :class => :User

  def validate
    super
    validates_unique :name, :message => "Ce nom d'équipe est déjà utilisé."
    validates_presence [ :name, :event_version, :race_type ], :message => 'Ce champ doit être renseigné'
  end

  def generate_invite_key
    self.invite_key = SecureRandom.urlsafe_base64(24)
  end

  def is_in?(u)
    self.vtt_id == u.id || route_id == u.id
  end

  def remove_from_team(u)
    if is_in?(u)
      self.vtt_id = nil if self.vtt_id == u.id
      self.route_id = nil if self.route_id == u.id
      
      # Save team if there is a member left
      # or delete if none
      if self.route_id or self.vtt_id
        self.save
      else
        self.delete
      end
    end
  end

end
