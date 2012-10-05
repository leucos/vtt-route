# encoding: utf-8
#
# 012_add_mazard_fleurs_sponsors.rb
#
# Adds new sponsors
#

Sequel.migration do
  change do
    transaction do
      self[:sponsors].insert(:name => 'Roger Mazard',
        :logo => 'images/sponsors/mazard.jpg', :url => '#',
        :description => 'Electicité - Chauffage - Domotique', :display => true)
      self[:sponsors].insert(:name => 'A Fleur d\'Eau',
        :logo => 'images/sponsors/a-fleur-deau.jpg', :url => '#',
        :description => 'Transmissions florales - Compositions', :display => true)
   end
  end
end

