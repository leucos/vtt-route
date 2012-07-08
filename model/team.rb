# encoding: UTF-8
#
class Team < Sequel::Model
  plugin :validation_helpers
  many_to_one :user

  def validate
    super
    validates_unique :name, :message => "Ce nom d'équipe est déjà utilisé."
    validates_unique :vtt_id, :message => "Cet équipier est déjà dans une autre équipe."
    validates_unique :route_id, :message => "Cet équipier est déjà dans une autre équipe."
    validates_presence [ :name, :event_version, :race_type ], :message => 'Ce champ doit être renseigné'
  end

end
