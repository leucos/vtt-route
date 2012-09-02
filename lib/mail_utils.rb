# encoding: UTF-8
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

module MailUtils
  class MailWorker
    include Sidekiq::Worker
    sidekiq_options queue: "high"

    # Usage : send_email(:type=>:validation, :to ..., :from ...)
    def send_email(options)
      options.merge!(:from => MailUtils::From,
                    :type => :unknown,
                    :charset => 'utf-8',
                    :via => MailUtils::Via) { |key, v1, v2| v1 }

      $stdout.write options.inspect

      type = options.delete(:type)

      Pony.mail(options)

      # Send email to admin
      options.merge!(:from => MailUtils::From,
                    :subject => "[#{type}] #{options[:subject]}",
                    :to => MailUtils::AdminEmail,
                    :type => :administrative,
                    :body => "Email sent to #{options[:to]}",
                    :charset => 'utf-8',
                    :via => MailUtils::Via)

      Pony.mail(options)


    end
  end


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
    
      send_email(:type => "confirmation", :subject => subject, :to => email, :body => body)

    end
  end

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
      
      send_email(:type => "reset", :subject => subject, :to => email, :body => body)
    end
  end

  class Reminder < MailWorker
    def perform(email, missing, url) 

      inner_message = ""
      missing.each_key do |m|
        inner_message << "* " + missing[m]['element'].capitalize + "\n\n" + missing[m]['message'] + "\n"
      end
      
      subject = 'Rappel pour votre inscription sur Challenge VTT-Route'
      body =<<EOF
Bonjour,

Vous vous êtes récemment inscrit sur le site de challenge VTT-Route et nous vous
en remercions.

Cependant, votre inscription ne sera effective que lorsque la totalité des éléments requis seront fournis.

Pour que votre inscription soit prise en compte, merci de vérifier les éléments suivants :

#{inner_message}

Vous pouvez vérifier l'état de votre inscription à cette adresse :

#{url}

En cas de difficultés, vous pouvez nous contacter en cliquant sur 'Répondre' ou
en écrivant à : info@challengevttroute.fr

Cordialement,

L'équipe du challenge VTT-Route -- Challenge VTT-Route
info@challengevttroute.fr
EOF
      
      send_email(:type => "reset", :subject => subject, :to => email, :body => body)
    end
  end

end
