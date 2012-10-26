# encoding: UTF-8
#
# Mail related utils
#

require 'sidekiq'
require 'pony'

require_relative '../config/sidekiq.rb'

Sidekiq.configure_client do |config|
    config.redis = { :namespace => 'org.chalengevttroute.www.sidekiq' }
end

Sidekiq.configure_server do |config|
    config.redis = { :namespace => 'org.chalengevttroute.www.sidekiq' }
end

# This modules handles mail related anctivities
# It will use sidekiq under the hood to manage it's mail sending
# business
module MailUtils
  # MailWorker is a base classe for sidekiq task handlers
  class MailWorker
    include Sidekiq::Worker
    sidekiq_options queue: "high"

    # Usage : send_email(:type=>:validation, :to ..., :from ...)
    def self.send_email(options)
      options.merge!(:from => MailUtils::From,
                    :type => :unknown,
                    :charset => 'utf-8',
                    :via => MailUtils::Via) { |key, first, second| first }

      type = options.delete(:type)
      who = options.delete(:admin) || "unknown"

      Pony.mail(options)

      # Send email to admin
      options.merge!(:from => MailUtils::From,
                    :subject => "[#{type}] #{options[:subject]}",
                    :to => MailUtils::AdminEmail,
                    :type => :administrative,
                    :body => "Email sent to #{options[:to]} by #{who}",
                    :charset => 'utf-8',
                    :via => MailUtils::Via)

      Pony.mail(options)
    end
  end

  # Confirmer sends confirmation emails
  class Confirmer < MailWorker
    def perform(email, confirm_url)
      subject = 'Inscription au challenge VTT-Route'
      body =<<EOF
Bonjour,

Afin de valider votre inscription au challenge VTT-Route, merci de bien
vouloir suivre ce lien :

#{confirm_url}

Vous pourrez ensuite inviter un coéquipier si vous participez à un 
challenge par équipes.

En cas de difficultés, vous pouvez nous contacter en cliquant sur 'Répondre'
ou en écrivant à : info@challengevttroute.fr

Cordialement,

L'équipe du challenge VTT-Route
--
Challenge VTT-Route
info@challengevttroute.fr
EOF
    
      MailWorker.send_email(:type => "confirmation", :subject => subject, :to => email, :body => body)

    end
  end

  # Reseter sends a password reset email to the specified recipient
  class Reseter < MailWorker
    def perform(email, url) 
      subject = 'Mot de passe perdu sur challenge VTT-Route'
      body =<<EOF
Bonjour,

Apparemment, vous avez perdu votre mot de passe. Ne vous inquiétez
pas, ça nous arrive à tous. Vous pouvez le ré-initialiser en vous
rendant à cette adresse :

#{url}

Si vous n'avez pas perdu votre mot de passe, quelqu'un doit faire une
mauvaise blague. Dans ce cas, vous pouvez ignorer ce message.

En cas de difficultés, vous pouvez nous contacter en cliquant sur
'Répondre' ou en écrivant à : info@challengevttroute.fr

Cordialement,

L'équipe du challenge VTT-Route
--
Challenge VTT-Route
info@challengevttroute.fr
EOF
      
      MailWorker.send_email(:type => "reset", :subject => subject, :to => email, :body => body)
    end
  end

  # Reminder send reminders to subscribers (e.g. you forgot this or
  # that)
  class Reminder < MailWorker
    def perform(email, missing, url, admin) 

      inner_message = ""
      missing.each_key do |key|
        inner_message << "* " + missing[key]['element'].capitalize + "\n\n" + missing[key]['message'] + "\n"
      end
      
      subject = 'Challenge VTT-Route : plus que 2 jours pour finaliser votre inscription'
      body =<<EOF
Bonjour,

Vous vous êtes récemment inscrit sur le site de challenge VTT-Route et nous vous
en remercions.

Cependant, votre inscription ne sera effective que lorsque la totalité des éléments requis seront fournis.
Ces éléments doivent être fournis sur place.

Pour que votre inscription soit prise en compte, merci de vérifier les éléments suivants :

#{inner_message}

Vous pouvez vérifier l'état de votre inscription à cette adresse :

#{url}

En cas de difficultés, vous pouvez nous contacter en cliquant sur 'Répondre' ou
en écrivant à : info@challengevttroute.fr

Cordialement,

L'équipe du challenge VTT-Route
--
Challenge VTT-Route
info@challengevttroute.fr
EOF
      
      MailWorker.send_email(:type => "remider", :subject => subject, :to => email, :body => body, :admin => admin)
    end
  end

  # General information
  class Informer < MailWorker
    def perform(email, url, admin) 
      subject = 'Challenge, j-2 !'
      body =<<EOF
Bonjour,

Quelques informations importantes à deux jours du Challenge :

  - le retrait des dossards commence à 7h.

  - le briefing a lieu à 8h45 

  - les participants licenciés devront IMPERATIVEMENT présenter une 
    licence sportive cycliste en cours de validité au retrait du
    dossard.
    N'oubliez pas ! Ce serait dommage de regarder les autres partir.

  - si vous réglez sur place, merci d'apporter un chèque. Aucun
    paiement par carte ne pourra être effectué et les règlements en
    espèce dépendront de la monnaie disponible en caisse.

  - n'hésitez pas à amener vos proches, de nombreuses manifestations 
    sont prévues le jour de l'épreuve :
     * 3 shows de VTT trial par Bruno Janin, champion du monde,
     * sécurité routiere pour les enfants
     * vélos rigolos, pour les enfants jusqu'à 99 ans
     * parcours trial, vélo électrique, spectacle de danse, buvette...

Vous pouvez télécharger le programme complet ici :
#{url}

Si vous avez besoin de nous contacter, vous pouvez le faire soit par 
email en cliquant sur 'Répondre' (ou en écrivant à : 
info@challengevttroute.fr) soit par téléphone en cas d'urgence
au 06 07 94 72 36

Rendez vous dimanche !

L'équipe du challenge VTT-Route
--
Challenge VTT-Route
info@challengevttroute.fr
EOF
      
      MailWorker.send_email(:type => "informer", :subject => subject, :to => email, :body => body, :admin => admin)
    end
  end


end
