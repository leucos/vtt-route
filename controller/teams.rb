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

    @team = user.route_team.first || user.vtt_team.first
  end

  def create
    @subtitle = "Créer une équipe"
  end

  def save
    data = request.subset(:name, :description, :race_type, 
                          :vtt_id, :route_id, :event_version,
                          :part, :open)

    data['event_version'] = VttRoute.options.edition
    pp data
    puts "race_type is #{data['race_type']}"
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
  end

  def join(bike, team, peer)
  end

  def swap(team)
  end

  def list
    paginate(Teams)
  end

  def leave
  end

end
