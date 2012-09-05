# encoding: UTF-8

# TeamS controller handles teams related actions

class Teams < Controller
  # the index action is called automatically when no other action is specified
  helper :fnordmetric, :form_helper

  FIELD_NAMES = {
    :name => "Nom",
    :description => "Description",
    :race_type => "Épreuve",
    :vtt_id => "Participant VTT",
    :route_id => "Participant Route"
  }

  before_all do
    redirect_referrer unless logged_in?
  end

  def index
    @title = 'Challenge VTT-Route'
    @subtitle = "Votre équipe"

    @team = Team.filter[{:vtt_id => user.id, :route_id => user.id}.sql_or]
  end

  def save
    data = request.subset(:name, :description, :race_type, 
                          :vtt_id, :route_id,
                          :handi, :part, :open)

    data['event_version'] = VttRoute.options.edition

    case data['race_type']
    when 'Solo'
      data['vtt_id'] = data['route_id'] = user.id
    when 'Duo'
      if data['part'] == 'Route'
        data['route_id'] = user.id
      else
        data['vtt_id'] = user.id
      end
    when 'Tandem'
      data['vtt_id'] = user.id
      # fuck that
      #TODO: fixme
    end

    data.delete('part')
    data.delete('open')

    begin
      Team.create(data)
    rescue Sequel::ValidationFailed => e
      Ramaze::Log.info(e.inspect)
      e.errors.each do |i|
        error_for i[0], "%s : %s" % [ FIELD_NAMES[i[0]], i[1][0] ]
      end
    end

    if has_errors?
      bulk_data data
      prepare_flash
      redirect_referrer
    end

    flash[:success] = "Equipe créée"
    redirect Teams.r(:index)
  end

  def join(bike, team_id, peer_id)
    bike.downcase!

    if !['vtt','route'].include?(bike)
      flash[:error] = "Type d'épreuve inconnue"
      redirect_referrer
    end

    t = Team[team_id]
    if !t.send("#{bike}_id").nil?
      flash[:error] = "Cette place est déjà prise"
      redirect_referrer
    else
      t.send("#{bike}_id=", peer_id)
    end
    t.save
  end

  def swap(team_id)
    t = Team[team_id]
    
    check_access(t)

    t.vtt_id, t.route_id = t.route_id, t.vtt_id
    t.save
    # flash[:success] = "Rôles inversés"
    redirect_referrer
  end

  def invite(team_id)
    t = Team[team_id]
    t.generate_invite_key
    t.save

    p = request.params['email']
    check_access(t)

    if p.nil?
      flash[:error] = "Adresse email non fournie"
      event(:edge_case, :_message =>  "Teams#invite:email_not_provided",
        :controller => "Teams#invite", :type => :email_not_provided)
    end

    peer = User[:email => p]

    flash[:error] = "Désolé, je ne connais personne à cette adresse." unless peer
    flash[:error] = "Désolé, cette personne a déjà une équipe." if peer and peer.has_team?

    if !flash[:error]
      send_invite(user.display_name, p, t)
      flash[:success] = "L'invitation à bien été envoyée à <strong>%s</strong>" % p
    end

    redirect_referrer
  end

  def list
    paginate(Teams)
  end

  def leave(team_id)
    t = Team[team_id]

    check_access(t)

    t.remove_from_team(user)
    redirect Teams.r(:index)
  end

  def confirm(email, id, key)
    t = Team[:id => id, :invite_key => key]
    u = User[:email => email]

    if !t
      flash[:error] = "Pas d'invitation à ce numéro" 
      event(:edge_case, :_message => "Teams#confirm:failed_no_such_record", 
        :controller => "Teams#confirm", :type => :failed_no_such_record) 
      redirect_referrer
    end
    if !u
      flash[:error] = "Pas d'invitation pour cet email" 
      event(:edge_case, :_message => "Teams#confirm:failed_no_such_email",
        :controller => "Teams#confirm", :type => :failed_no_such_email) 
      redirect_referrer
    end

    if t.vtt_id and t.route_id  
      flash[:error] = "Désolé, la place est prise" 
      event(:edge_case, :_message => "Teams#confirm:failed_no_room_left",
        :controller => "Teams#confirm", :type => :failed_no_room_left) 
      redirect_referrer
    end

    if t.vtt_id 
      t.route_id = u.id
    else
      t.vtt_id = u.id
    end

    t.save
    flash[:success] = "Félicitations, vous avez été ajouté à l'équipe !" 
    redirect Teams.r(:index)
  end

  private

  # Bails out and redirects if member is not member of team
  def check_access(team)
    if !team.is_in?(user)
      flash[:error] = "Vous ne faites pas partie de cette équipe"
      redirect_referrer
    end
  end

  def send_invite(from, email, team)
    #:nocov:
    body =<<EOF
Bonjour,

#{from} souhaite vous inviter dans son équipe "#{team.name}".

Si vous désirez vous joindre à lui, il suffit de cliquer sur ce lien  :

#{VttRoute.options.myurl}/#{Teams.r(:confirm, email, team.id, team.invite_key)}

Dans le cas contraire, vous pouvez simplement ignorer ce message.

En cas de difficultés, vous pouvez nous contacter en cliquant sur 'Répondre'
ou en écrivant à : info@challengevttroute.fr

Cordialement,

L'équipe du challenge VTT-Route
--
Challenge VTT-Route
info@challengevttroute.fr
EOF

  Ramaze::Log.info("sending invite email to #{email}");
  event(:email_sent, :type => :invite)
  Pony.mail(:to => email,
            :from => 'info@challengevttroute.fr',
            :subject => 'Invitation dans une équipe du challenge VTT-Route',
            :body => body,
            :via => :sendmail)

  event(:email_sent, :type => :administrative)
  Pony.mail(:to => VttRoute.options.admin_email,
            :from => 'info@challengevttroute.fr',
            :subject => '[vtt-route] Invitation envoyée',
            :body => "L'utilisateur #{from} a invité #{email} dans l'équipe #{team.id}",
            :via => :sendmail)
  #:nocov:
  end
end


