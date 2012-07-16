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

  def create
    @subtitle = "Créer une équipe"
  end

  def save
    data = request.subset(:name, :description, :race_type, 
                          :vtt_id, :route_id, :event_version,
                          :part, :open)

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
    if (t.vtt_id != user.id and t.route_id != user.id)
      flash[:error] = "Vous n'êtes pas dans cette équipe !"
      redirect_referrer
    end

    t.vtt_id, t.route_id = t.route_id, t.vtt_id
    t.save
    flash[:success] = "Rôles inversés"
    redirect_referrer
  end

  def list
    paginate(Teams)
  end

  def leave(team_id)
    t = Team[team_id]

    check_access(Team[team_id])

    t.remove_from_team(user)
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

end
