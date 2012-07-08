# encoding: UTF-8

# TeamS controller handles teams related actions

class Teams < Controller
  # the index action is called automatically when no other action is specified
  helper :fnordmetric, :form_helper

  before_all do
    redirect_referrer unless logged_in?
  end

  def index
    @title = 'Challenge VTT-Route'
    @subtitle = "Votre équipe"

    @team = Team.filter({:vtt_id => user.id} | {:route_id => user.id}).first
  end

  def create
    @subtitle = "Créer une équipe"
  end

  def save
    form = request.subset(:name, :description, :race_type, :vtt_id, :route_id, :event_version)
    form[:event_version] = VttRoute.options.edition
    begin
      Team.create(form)
    rescue Sequel::ValidationFailed => e
      Ramaze::Log.info(e.inspect)
      e.errors.each do |i|
        Ramaze::Log.info("error with field #{i[0]}")
        flash[:error] = e.message
        redirect_referrer
      end
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
