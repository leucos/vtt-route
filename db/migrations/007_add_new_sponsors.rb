# encoding: utf-8
# 00è_add_new_sponsors.rb
#
# Adds a sponsors table
#

Sequel.migration do
  change do
    transaction do
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

      self[:sponsors].insert(:name => 'Asterion',
        :logo => 'images/sponsors/asterion.jpg', :url => 'http://www.asterion-wheels.com',
        :description => 'Roues de vélo hautes performances VTT et route', :display => true)

      self[:sponsors].insert(:name => 'Entreprise Générale Delorme Bras',
        :logo => 'images/sponsors/bras.jpg', :url => '',
        :description => 'Plomberie - Électricité - Chauffage - Énergies renouvelables', :display => true)

      self[:sponsors].insert(:name => 'Crédit Agricole Centre-Est',
        :logo => 'images/sponsors/cace.jpg', :url => 'http://www.ca-centrest.fr',
        :description => 'Banque pour les particuliers, professionnels et entreprise', :display => true)

      self[:sponsors].insert(:name => 'Créalec',
        :logo => 'images/sponsors/crealec.jpg', :url => '',
        :description => 'L\'électricité au service de vos idées', :display => true)

      self[:sponsors].insert(:name => 'Boulangerie Patisserie Ducreux',
        :logo => 'images/sponsors/ducreux.jpg', :url => '',
        :description => 'Boulagerie patisserie Sylviane et Patrick Ducreux - Saint Laurent de Chamousset', :display => true)

      self[:sponsors].insert(:name => 'ECML',
        :logo => 'images/sponsors/ecml.jpg', :url => 'http://www.ecml.net/',
        :description => 'Eau Confort des Monts du Lyonnais', :display => true)

      self[:sponsors].insert(:name => 'Ekoï',
        :logo => 'images/sponsors/ekoi.jpg', :url => 'http://www.ekoi.fr/',
        :description => 'JCR EKOI', :display => true)

      self[:sponsors].insert(:name => 'Ets Ducreux - Disgroup',
        :logo => 'images/sponsors/ets_ducreux.jpg', :url => '',
        :description => 'Spécialiste de la distribution au service des métiers de bouche', :display => true) # site hacké

      self[:sponsors].insert(:name => 'Garage Blein',
        :logo => 'images/sponsors/garage_blein.jpg', :url => 'http://garageregisblein.pagesperso-orange.fr/',
        :description => 'Garage Régis Blein - villechenève', :display => true)

      self[:sponsors].insert(:name => 'G.Cycles',
        :logo => 'images/sponsors/gcycles.jpg', :url => 'http://www.g-cycles.fr/',
        :description => 'Idéalement situé en plein cœur des Mont du Lyonnais, le magasin dispose d’une surface totale de 170 m² et d’un accès facilité par la présence d’un parking à proximité.', :display => true)

      self[:sponsors].insert(:name => 'Hutchinson',
        :logo => 'images/sponsors/hutchinson.jpg', :url => 'http://www.hutchinson-pneus.com/fr/',
        :description => 'It\'s your ride', :display => true)

      self[:sponsors].insert(:name => 'Intersport',
        :logo => 'images/sponsors/intersport.jpg', :url => 'http://www.intersport.fr/',
        :description => 'Le sport commence ici', :display => true)

      self[:sponsors].insert(:name => 'Kony',
        :logo => 'images/sponsors/kony.jpg', :url => 'http://www.boutiquekony.com/fr/',
        :description => 'Vétements techniques pour le cyclisme', :display => true)

      self[:sponsors].insert(:name => 'Ltr Cycles',
        :logo => 'images/sponsors/ltr_cycles.jpg', :url => 'http://www.ltr-cycles.fr/',
        :description => '', :display => true) # http://www.ltr-cycles.fr/ => vide

      self[:sponsors].insert(:name => 'Materiel Vélo',
        :logo => 'images/sponsors/materiel_velo.jpg', :url => 'http://www.materiel-velo.com/',
        :description => 'Tout le vélo en ligne', :display => true)

      self[:sponsors].insert(:name => 'Garage Michaud',
        :logo => 'images/sponsors/michaud.jpg', :url => 'http://www.renault.fr/concession/garage_michaud',
        :description => 'Concessionaire Renault-Dacia, Saint Laurent de Chamousset', :display => true)

      self[:sponsors].insert(:name => 'Passelègue',
        :logo => 'images/sponsors/passelegue.jpg', :url => '',
        :description => 'Charpente et couverture, Saint Laurent de Chamousset', :display => true)

      self[:sponsors].insert(:name => 'François Chanavat',
        :logo => 'images/sponsors/primeur.jpg', :url => '',
        :description => 'Primeurs, Saint Laurent de Chamousset', :display => true)

      self[:sponsors].insert(:name => 'SARL Berthoud Barange',
        :logo => 'images/sponsors/sarl_berthoud.jpg', :url => '',
        :description => 'Charpente et couverture, Saint Laurent de Chamousset', :display => true)

      self[:sponsors].insert(:name => 'SARL Richard',
        :logo => 'images/sponsors/sarl_richard.jpg', :url => '',
        :description => 'Boucherie - charcuterie - triperie - volailles, Saint Laurent de Chamousset', :display => true)

      self[:sponsors].insert(:name => 'Seret',
        :logo => 'images/sponsors/seret.jpg', :url => '',
        :description => '', :display => true)

      self[:sponsors].insert(:name => 'Sa Suntour',
        :logo => 'images/sponsors/sr_suntour.jpg', :url => 'http://www.srsuntour-cycling.com/',
        :description => 'Commited to cycling since 1912', :display => true)
    end
  end
end

