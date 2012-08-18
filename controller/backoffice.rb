class Backoffice < Controller
  helper :paginate
  layout :backoffice

  trait :paginate => {
    :limit => 20,
    :var   => 'page',
    :css   => {
      :disabled => 'disabled',
      :prev     => 'previous',
    # and so on.
    }
  }

  before_all do
    if !logged_in? or !user.admin
      event(:edge_case, :controller => "Backoffice#before_all", :type => :acces_denied) 
      redirect_referrer
    end
  end

  def index
    u = User.filter(:admin=>false, :superadmin=>false)
    @equipes = Team.count
    @inscrits = u.count
    begin
      @avancement = 100*(Team.where(:vtt_id => nil).count + Team.exclude(:route_id => nil).count)/@inscrits 
    rescue ZeroDivisionError
      @avancement = 100
    end

    @subscribers = paginate(u)
  end
end

