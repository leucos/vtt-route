# encoding: UTF-8
#

SIDEKIQ_WEB_PORT=1234

class MailWorker
  From = 'info@challengevttroute.fr'
  AdminEmail = 'mb@mbnet.fr'
  Via = :sendmail
end
