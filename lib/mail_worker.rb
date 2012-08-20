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

class MailWorker
  include Sidekiq::Worker
  sidekiq_options queue: "high"

  # Usage : send_email(:type=>:validation, :to ..., :from ...)
  def send_email(options)
    options.merge!(:from => MailWorker::From,
                  :type => :unknown,
                  :charset => 'utf-8',
                  :via => MailWorker::Via) { |key, v1, v2| v1 }

    $stdout.write options.inspect

    type = options.delete(:type)

    Pony.mail(options)

    # Send email to admin
    options.merge!(:from => MailWorker::From,
                  :subject => "[#{type}] #{options[:subject]}",
                  :to => MailWorker::AdminEmail,
                  :type => :administrative,
                  :body => "Email sent to #{options[:to]}",
                  :charset => 'utf-8',
                  :via => MailWorker::Via)

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

    def send_reset_email(email, key) 
      body =<<EOF
Bonjour,

Apparemment, vous avez perdu votre mot de passe. Ne vous inquiétez
pas, ça nous arrive à tous. Vous pouvez le ré-initialiser en vous
rendant à cette adresse :

#{VttRoute.options.myurl}/#{r(:lost_password, key)}

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
      
      send_email(:type => "reset", :subject => subject, :body => body)
    end
  end

