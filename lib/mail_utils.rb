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
      subject = 'Un grand merci à tous !'
      body =<<EOF
Bonjour,

Un grand merci pour votre participation au Challenge VTT-Route. Vous
avez transformé cette première en succès, malgré la météo exécrable.
Bravo pour votre courage, et merci !

Une mention spéciale aux équipes handi dont la détermination dans le vent 
et le froid ont forcé le respect de tous. Chapeau !

Nous avons mis en ligne les photos prises par nos signaleurs et autres 
bénévoles à cette adresse : 

https://picasaweb.google.com/105811499874742518418

Les bénéfices de la vente photo devaient aller intégralement à 
l'association Handisport Val d'Ozon. Si vous désirez soutenir leur 
action, n'hésitez pas. Vous trouverez les informations nécessaires sur 
leur site (http://www.handisport-valdozon.fr/).

Par ailleurs, vous trouverez quelques vidéos tournées à la va-vite ici :

https://www.youtube.com/watch?v=z6g7TOKOHvw&list=PLOF4_z8_YdVWNLRB5VcqA-UIOWP9b7T_L&feature=view_all

La qualité est très amateur mais l'idée c'était surtout d'avoir un 
petit souvenir de cette édition à se repasser les soirs d'hiver, en 
attendant de faire mieux la prochaine fois.

Justement, nous avons besoin de votre avis pour améliorer les circuits,
l'organisation, la restauration, etc... Vous trouverez un petit formulaire
à remplir ici :

http://chalengevttroute.fr/formulaire

Ç'est anonyme, ça prend moins de 3 minutes, et votre avis est vraiment 
important pour nous. Alors merci d'avance !

J'allais oublier, quelque chose qui probablement vous intéresse : les 
classements ! Ils sont disponibles sur le site, en page d'accueil : 
http://challengevttroute.fr/

Nous conservons votre email afin de pouvoir vous prévenir pour la 
prochaine édition mais sachez que conformément à la loi, vous disposez 
d'un droit de consultation et de rectification. Pour faire simple, si 
vous désirez disparaître de nos tablettes il suffit de nous le demander 
par courriel, ce sera fait sur le champ sans aucune question. Par 
ailleurs, sachez qu'en aucun cas ces informations ne sont transmises 
à des tiers; vous ne recevrez donc aucun "pourriel" à cause de nous.

Si vous avez besoin de nous contacter, vous pouvez le faire soit par 
courriel en cliquant sur 'Répondre' (ou en écrivant à : 
info@challengevttroute.fr).

Merci de votre confiance, et rendez vous à la prochaine édition !

L'équipe du challenge VTT-Route
--
Challenge VTT-Route
info@challengevttroute.fr
EOF
      
      MailWorker.send_email(:type => "informer", :subject => subject, :to => email, :body => body, :admin => admin)
    end
  end


end
