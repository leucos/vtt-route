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
      @subtitle = "#{u.count} inscrits"
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
    @subtitle = "#{u.count} inscrits sans profil"
    @subscribers = paginate(u)
  end

  def userslookup(filter = nil)
    u = User.filter(:admin=>false, :superadmin=>false).select(:id)
    Profile.where(:user_id => u).all
  end

  def teams
    @teams = paginate(Team)
    @subtitle = "#{@teams.count} équipes"
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
    sent = 0
    User.each do |u|
      sent += 1 if do_remind(u).count > 0
    end
    
    flash[:info] = "#{sent} rappels envoyés"
    redirect_referrer
  end

  def remind(id=nil)
    if !id
      flash[:error] = "Utilisateur non fourni"
      redirect_referer
    end

    u = User[id]

    if !u
      flash[:error] = "Utilisateur inconnu"
      redirect_referer
    end

    do_remind(u).each do |what|
      flash[:info] = flash[:info].to_s + what.to_s
    end

    if flash[:info]
      flash[:info] = "Rappel envoyé à #{u.email} pour : #{flash[:info]}"
    else
      flash[:info] = "Aucun rappel nécessaire"
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

    if missing.count > 0
      Ramaze::Log.info "Sending reminder to #{u.email}"
      MailUtils::Reminder.perform_async(u.email, missing, "#{VttRoute.options.myurl}/#{Registrations.r(:index)}")
    end

    missing.keys
  end
end

