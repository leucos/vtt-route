#
# App Settings
#

Rack::Mime::MIME_TYPES['.gpx'] = 'application/octet-stream'

class VttRoute
  include Ramaze::Optioned

  options.dsl do
    o 'The GitHub repository URL', :github, 'https://github.com/leucos/vtt-route/'
    o 'The base application URL', :myurl, 'http://www.challengevttroute.fr'
    o 'The application version', :version, '0.0.2'
    # :preinscriptions => pré-inscriptions
    # :inscriptions    => inscriptions, consultation de profil
    # :closed          => plus d'inscriptions
    # :started         => course en cours
    # :finished        => course terminée
    o 'The running state', :state, :inscriptions
    o 'Show sponsors scrolling banner', :show_sponsors, false

  end
end
