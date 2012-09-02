# coding: utf-8

class Backoffice < Controller
  helper :paginate
  layout :backoffice 
  set_layout nil => [ :userslookup ]

  trait :paginate => {
    :limit => 20,
    :var   => 'page',
    :css   => {
      :disabled => 'disabled',
      :prev     => 'previous',
    }
  }

  provide(:json, :type => 'application/json') do |action, value|
    # "value" is the response body from our controller's method
    Ramaze::Log.info(value.to_json)
    value.to_json
  end

  before_all do
    if !logged_in? or !user.admin
      event(:edge_case, :controller => "Backoffice#before_all", :type => :acces_denied) 
      redirect_referrer
    end

    # Save controller name and action method for view nav
    @caller = { :controller => action.node, 
                :method => action.method }
  end

  def users(filter = nil)
    if (!request.xhr?)
      u = User.filter(:admin=>false, :superadmin=>false)
      @subscribers = paginate(u)
    else
      Ramaze::Log.info("got ajax request")
      u = User.filter(:admin=>false, :superadmin=>false).select(:id)
      p = Profile.where(:user_id => u)
      @subscribers = p.where(Sequel.ilike(:name, "%#{filter}%")).all
    end
  end

  def noprofile
    p = Profile.select(:id)
    u = User.where(:id => p).invert

    @subscribers = paginate(u)
  end

  def userslookup(filter = nil)
    u = User.filter(:admin=>false, :superadmin=>false).select(:id)
    Profile.where(:user_id => u).all
  end

  def teams
    @teams = paginate(Team)
  end

  def tools
    # Ajax only tools
  end

  # def add_user
  #   values = request.subset(["name", "surname"] and blah blah blah)
  #   u = User.create(:email => "P##{values[:name]}/#{:surname}", :password => SecureRandom.urlsafe_base64(12))
  #   u.profile = Profile.create(blah blah blah)
  # end

  def statistics
    Ramaze::Log.info("in statistics")
    u = User.filter(:admin=>false, :superadmin=>false)
    @equipes = Team.count
    @inscrits = u.count
    @subtitle = "#{@inscrits} inscrits - #{@equipes} équipes"

    begin
      @avancement = 100*(Team.where(:vtt_id => nil).count + Team.exclude(:route_id => nil).count)/@inscrits 
    rescue ZeroDivisionError
      @avancement = 100
    end
  end

  def remind_all
    User.each do |u|
      do_remind(u)
    end
  end

  def remind(id=nil)
    if !id
      flash[:error] = "Utilisateur non fourni"
      redirect_referer
    end

    u = User[id]

    if !user
      flash[:error] = "Utilisateur inconnu"
      redirect_referer
    end

    flash[:info] = "Rappel envoyé à #{u.email} pour : "

    do_remind(u).each do |what|
      flash[:info] << what.to_s
    end

    redirect_referer
  end

  private

  def do_remind(u)
    # Send reminder to user
    missing = Hash.new

    if !u.profile
      missing[:profile] = Hash.new
      missing[:profile][:element] = "vous n'avez pas rempli votre profil"
      missing[:profile][:message]=<<EOF
  Pour participer au challenge, vous devez renseigner votre profil.
  Pour cela, connectez vous sur le site, et cliquez sur 'Mon Profil' 
  dans le menu ou suivez ce lien : 
  #{VttRoute.options.myurl}/#{Profiles.r(:index)}
EOF
    end

    MailUtils::Reminder.perform_async(u.email, missing, "#{VttRoute.options.myurl}/#{Registrations.r(:index)}")

    missing.keys
  end
end

