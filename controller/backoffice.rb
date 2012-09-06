# coding: utf-8

class Backoffice < Controller
  helper :paginate, :form_helper

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
      event(:edge_case, :_message => "Backoffice#before_all:acces_denied",
        :controller => "Backoffice#before_all", :type => :acces_denied) 
      redirect_referrer
    end

    # Save controller name and action method for view nav
    @caller = { :controller => action.node, 
                :method => action.method }
  end

  # Toggles whether a docume,t has been received or not
  # Returns true or ""
  def toggle_document(document, profile_id)
    return if (!request.xhr?)

    p = Profile[profile_id]

    return "invalid document" unless ["payment","authorization","certificate"].include?(document)

    method_received = "#{document}_received"
    method_required = "#{document}_required?"

    return "not required" unless p.send(method_required)

    # Ramaze::Log.info("pre state for #{method_received} : #{p.send(method_received)}")

    p.send("#{method_received}=", !p.send(method_received))

    # Ramaze::Log.info("post state for #{method_received} : #{p.send(method_received)}")

    p.save
    p.send(method_received)
  end

  def create_user
    render_view(:userform)
  end

  def save_user
    data = request.subset(:userid, :name, :surname, :gender,
                          :address1, :address2, :zip, :city, :country,
                          :phone, :org, :licence, :event, :federation,
                          :emergency_contact)

    if data[:userid]
      prof = Profile[:user_id => data[:userid]]

      if prof.nil?
        flash[:error] = 'Profil invalide'

        redirect_referrer
      end

      operation = :update
    else
      usr = User.new
      prof = Profile.new
      operation = :create
    end

    # Now let's update the User instance
    # Since many things can fail, we enclose this in a rescue block
    begin
      date_str = "%s-%s-%s" % [ request.params['dob-year'],
                                request.params['dob-month'],
                                request.params['dob-day'] ]
      data[:birth] = Date.parse(date_str)
    rescue
      # Let Sequel handle this and report back
      data[:birth] = nil
    end

    begin
      prof.raise_on_typecast_failure = false
      Ramaze::Log.info(data.inspect)
      prof.update(data)

    rescue Sequel::ValidationFailed => e
      Ramaze::Log.info(e.inspect)
      e.errors.each do |i|
        error_for i[0], "%s : %s" % [ FIELD_NAMES[i[0]], i[1][0] ]
      end
    end

    if !request.params['accept'] and operation == :create
      Ramaze::Log.info("Accept not checked")
      error_for :accept, "Vous n'avez pas coché la case d'acceptation du règlement" 
    end

    if has_errors?
      # An error occured, so let's save form data
      # so the user doesn't have to retype everything
      #flash[:form_data] = data
      ['dob-day', 'dob-month', 'dob-year'].each do |d|
        data_for d, request.params[d]
      end

      bulk_data data
      prepare_flash
      redirect_referrer
    end

    user.profile = prof
    user.save

    #user.profile = prof

    flash[:success] = 'Profil mis à jour'
    @title = 'Profil'

    redirect Profiles.r(:index)
  end

  def users(filter = nil)
    if (request.xhr?)
      Ramaze::Log.info("got ajax request")
      u = User.filter(:admin=>false, :superadmin=>false).select(:id)
      p = Profile.where(:user_id => u)
      @subscribers = p.where(Sequel.ilike(:name, "%#{filter}%")).or(Sequel.ilike(:surname, "%#{filter}%")).all
    else   
      u = User.filter(:admin=>false, :superadmin=>false)
      @subscribers = paginate(u)
      @subtitle = "#{u.count} inscrits"
    end
  end

  def noprofile
    p = Profile.select(:user_id)
    u = User.where(:id => p).invert.filter(:admin=>false, :superadmin=>false)

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

    return unless u.email =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/

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

