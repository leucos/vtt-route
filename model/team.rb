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

end
