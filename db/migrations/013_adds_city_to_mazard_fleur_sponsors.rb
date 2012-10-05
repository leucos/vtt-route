# encoding: utf-8
#
# 013_adds_city_to_mazard_fleurs_sponsors.rb
#
# Adds new sponsors
#

Sequel.migration do
  change do
    transaction do
      self[:sponsors].where(:name => 'Roger Mazard').update(:description => 'Electicité - Chauffage - Domotique - Saint Laurent de Chamousset')
      self[:sponsors].where(:name => 'A Fleur d\'Eau').update(:description => 'Transmissions florales - Compositions - Saint Laurent de Chamousset')
   end
  end
end

