# encoding: utf-8
# 004_sponsors_table.rb
#
# Adds a sponsors table
#

Sequel.migration do
  up do
    transaction do
      create_table(:sponsors) do
        primary_key :id
        String :name, :size => 255
        String :logo, :size => 255
        String :url, :size => 255
        String :description, :text => true
        TrueClass :display, :default => true
      end

      # add first sponsors
      self[:sponsors].insert(:name => 'Communauté de Communes de Chamousset en Lyonnais', 
        :logo => 'images/sponsors/cccl.jpg', :url => 'http://www.chamousset-en-lyonnais.com',
        :description => 'Communauté de Communes de Chamousset en Lyonnais', :display => true)

      self[:sponsors].insert(:name => 'Collège Saint Laurent de Chamousset', 
        :logo => 'images/sponsors/col_slc.jpg', :url => 'http://www.college-st-laurent.fr',
        :description => 'Communauté de Communes de Chamousset en Lyonnais', :display => true)

      self[:sponsors].insert(:name => 'Handisport Val d\'Ozon', 
        :logo => 'images/sponsors/handi_val_ozon.jpg', :url => '#',
        :description => 'Handisport Val d\'Ozon', :display => true)

      self[:sponsors].insert(:name => 'O"rka', 
        :logo => 'images/sponsors/orka.jpg', :url => 'http://www.orka-cycles.com/',
        :description => 'O"rka', :display => true)

      self[:sponsors].insert(:name => 'Département du Rhône', 
        :logo => 'images/sponsors/rhone.jpg', :url => 'http://www.rhone.fr', :description => 'Département du Rhône', :display => true)

      self[:sponsors].insert(:name => 'Commune de Saint Laurent de Chamousset', 
        :logo => 'images/sponsors/slc.jpg', :url => 'http://chamousset-en-lyonnais.com/index.php?page=st-laurent',
        :description => 'Commune de Saint Laurent de Chamousset', :display => true)

      self[:sponsors].insert(:name => 'Union Nationale du Sport Scolaire', 
        :logo => 'images/sponsors/unss.jpg', :url => 'http://www.unss.org/',
        :description => 'Union Nationale du Sport Scolaire', :display => true)
    end
  end

  down do
    drop_table(:sponsors)
  end
end

