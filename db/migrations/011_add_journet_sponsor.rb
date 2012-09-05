# encoding: utf-8
#
# 007_add_new_sponsors.rb
#
# Adds new sponsors
#

Sequel.migration do
  change do
    transaction do
      self[:sponsors].insert(:name => 'Journet Bois',
        :logo => 'images/sponsors/journet.jpg', :url => 'http://www.journetbois.fr/',
        :description => 'Construction Maisons en Bois - Ossatures - Chalets - Extensions - Surélévation', :display => true)
   end
  end
end

