# encoding: utf-8
#
# 014_adds_url_to_val_ozon.rb
#
# Fixes url
#

Sequel.migration do
  change do
    transaction do
      self[:sponsors].where(:name => 'Handisport Val d\'Ozon').update(:url => 'http://www.handisport-valdozon.fr/')
   end
  end
end

