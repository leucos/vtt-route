# coding: utf-8
require 'csv'

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

  TEAM_FIELD_NAMES = {
    :name => "Nom",
    :description => "Description",
    :race_type => "Épreuve",
    :vtt_id => "Participant VTT",
    :route_id => "Participant Route"
  }

  USER_FIELD_NAMES = { :name  => "Nom",
                  :surname => "Prénom",
                  :gender  => "Sexe",
                  :address1 => "Adresse",
                  :address2 => "Complément d'adresse",
                  :zip => "Code Postal",
                  :city => "Ville",
                  :country => "Pays",
                  :phone => "Téléphone",
                  :org => "Club ou entreprise", 
                  :birth => "Date de naissance", 
                  :licence => "Numéro de licence",
                  :federation => "Fédération",
                  :event => "Epreuve",
                  :emergency_contact => "Personne à contacter en cas d'urgence" }

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

  def edit_user(id=nil)
    @title = 'Espace participants'
    @subtitle = 'Profil'

    usr = User[id] if id

    if usr
      usr = User[id]
      data_for('user_id',id)
    else
      flash[:error] = 'Utilisateur inexistant'
      redirect_referrer
    end

    # Quite ugly, but we don't want to use 'if's in view
    if usr.profile
      USER_FIELD_NAMES.each_key do |f|
        data_for( f.to_s, usr.profile[f] )
      end

      dte = usr.profile.birth
      ['day','month','year'].each { |t| data_for("dob-#{t}", dte.send(t)) }
    end

    render_view(:userform)
  end

  def save_user(id=nil)
    data = request.subset(:name, :surname, :gender,
                          :address1, :address2, :zip, :city, :country,
                          :phone, :org, :licence, :event, :federation,
                          :emergency_contact)

    if id
      usr = User[id]

      if usr.nil?
        flash[:error] = 'Utilisateur invalide'
        redirect_referrer
      end

      prof = usr.profile ? usr.profile : Profile.new
      operation = :update
    else
      usr = User.new
      usr.password = SecureRandom.urlsafe_base64(20)
      usr.email = "P/#{data['name']}-#{data['surname']}/#{SecureRandom.urlsafe_base64(4)}"
      Ramaze::Log.info("setting email to #{usr.email}")
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
        error_for i[0], "%s : %s" % [ USER_FIELD_NAMES[i[0]], i[1][0] ]
      end
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

    if operation == :create
      usr.save
      prof.save
      usr.profile = prof
    else
      prof.save
      usr.profile = prof
    end

    flash[:success] = 'Utilisateur et profil enregistrés'
    @title = 'Profil'

    redirect Backoffice.r(:users)
  end

  def create_team(uid=nil)
    data = request.subset(:name, :description, :race_type, 
                          :vtt_id, :route_id,
                          :handi, :part, :open)

    data['event_version'] = VttRoute.options.edition

    if uid == nil or !User[uid]
      flash[:error] = "Utilisateur introuvable"
      redirect_referrer
    end

    case data['race_type']
    when 'Solo'
      data['vtt_id'] = data['route_id'] = uid
    when 'Duo'
      if data['part'] == 'Route'
        data['route_id'] = uid
      else
        data['vtt_id'] = uid
      end
    when 'Tandem'
      data['vtt_id'] = uid
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
        error_for i[0], "%s : %s" % [ TEAM_FIELD_NAMES[i[0]], i[1][0] ]
      end
    end

    redirect_referrer
  end

  def users(filter = nil)
    filter = request.params["search"] if request.params.key?("search")

    if (request.xhr?)
      Ramaze::Log.info("got ajax request")
      u = User.filter(:admin=>false, :superadmin=>false).select(:id)
      p = Profile.where(:user_id => u)
      @subscribers = p.where(Sequel.ilike(:name, "%#{filter}%")).or(Sequel.ilike(:surname, "%#{filter}%")).all
    else   
      p = Profile.where(Sequel.ilike(:name, "%#{filter}%")).or(Sequel.ilike(:surname, "%#{filter}%")).select(:user_id)
      u = User.where(:id => p).or(Sequel.ilike(:email, "%#{filter}%"))
      u = u.where(:admin=>false, :superadmin=>false)

      @subscribers = paginate(u)
      @subtitle = "#{u.count} inscrits"
      @free_teams = Team.where(:vtt_id => nil).or(:route_id => nil)
    end
  end

  def noprofile
    p = Profile.select(:user_id)
    u = User.where(:id => p).invert.filter(:admin=>false, :superadmin=>false)

    @subtitle = "#{u.count} inscrits sans profil"
    @subscribers = paginate(u)
  end

  def add_to_team(uid)
    Ramaze::Log.info request.params["team_id"]
    t = Team[request.params["team_id"]]

    if !t 
      flash[:error] = "Equipe inconnue"
      redirect_referrer
    end

    free = t.has_free_spot?

    if !free or ![:vtt,:route].include?(free)
      flash[:error] = "Type d'épreuve inconnue"
      redirect_referrer
    end

    if !t.send("#{free.to_s}_id").nil?
      flash[:error] = "Cette place est déjà prise"
      redirect_referrer
    else
      t.send("#{free.to_s}_id=", uid)
    end
    t.save
  
    redirect_referrer
  end

  def remove_from_team(tid,uid)
    t = Team[tid]
    u = User[uid]

    if !t or !u
      flash[:error] = "Equipe ou utilisateur inconnu"
      redirect_referrer
    end

    t.remove_from_team(u)
    redirect_referrer
  end

  def userslookup(filter = nil)
    u = User.filter(:admin=>false, :superadmin=>false).select(:id)
    Profile.where(:user_id => u).all
  end

  def teams
    @teams = paginate(Team.order_by(:name))

    catcount= Hash.new
    tc = Team.group_and_count(:race_type).all
    tc.map { |x| catcount[x[:race_type]] = x[:count] }

    @subtitle = "#{Team.count} équipes (#{catcount['Solo']} solo, #{catcount['Duo']} duo, #{catcount['Tandem']} tandem)"
  end

  def tools
    # Ajax only tools
  end

  # def add_user
  #   values = request.subset(["name", "surname"] and blah blah blah)
  #   u.profile = Profile.create(blah blah blah)
  # end

  def csv_export_chrono
    csv_string = CSV.generate do |csv|

      csv << [ "Plaque", "Equipe", "Nom VTT", "Prenom VTT", "ADN VTT", "Nom Route", "Prenom Route", "ADN Route", "Categorie"]

      Team.order_by(:plate).each do |t|
        cat = t.category
        next unless cat

        cname = cat.map { |v| v.capitalize }.join('-')
        csv << [ t.plate, t.name, 
          t.vtt.profile.name.upcase, t.vtt.profile.surname.capitalize, t.vtt.profile.birth.year, 
          t.route.profile.name.upcase, t.route.profile.surname.capitalize, t.route.profile.birth.year, cname]
      end
    end

    respond!(csv_string, 200, 'Content-Type' => 'text/csv')
  end

  def csv_export_users
    csv_string = CSV.generate do |csv|
      csv << [ "Nom", "Prénom", "Equipe", "Categorie" ]

      User.each do |u|
        next unless u
        next if u.superadmin or u.admin
        next unless u.team and !u.team.has_free_spot?
        next unless u.profile

        csv << [ u.profile.name.upcase,
          u.profile.surname.capitalize,
          u.team.plate,
          u.team.name.capitalize,          
          u.team.category.map { |v| v.capitalize }.join('-')
        ]
      end
    end
    respond!(csv_string, 200, 'Content-Type' => 'text/csv')
  end

  def csv_export_retrait
    csv_string = CSV.generate do |csv|

      csv << [ "Nom", "Prénom", "ADN", "Manquant", "Catégorie", "Plaque", "NomP", "PrenomP", "ADNP", "ManquantP"]
      
      DB.fetch("SELECT profiles.name as n, profiles.user_id as uid,
        teams.plate as p 
        FROM profiles, teams 
        WHERE profiles.user_id = teams.vtt_id 
        ORDER BY profiles.name").each do |m|      

        u = User[m[:uid]]
        next unless u
        next if u.superadmin or u.admin
        next unless u.team and !u.team.has_free_spot?

        p = u.profile
        missing = Array.new

        missing << :paiement if u.profile.payment_required? and !u.profile.payment_received
        missing << :certif if u.profile.certificate_required? and !u.profile.certificate_received
        # missing << :licence if u.profile.licence.nil? or u.profile.licence == ''
        missing << :licence if (not u.profile.licence.nil? and u.profile.licence != '')
        missing << :authoris if u.profile.authorization_required? and !u.profile.authorization_received
        miss = missing.join('+').upcase
        miss = "OK" if miss == ""

        t = u.team
        next unless t
        cat = t.category
        next unless cat
        cname = cat.map { |v| v.capitalize }.join('-')
 
        other_id = (t.vtt_id == u.id ? t.route_id : t.vtt_id )
        o = User[other_id].profile

        missingo = Array.new

        missingo << :paiement if o.payment_required? and !o.payment_received
        missingo << :certif if o.certificate_required? and !o.certificate_received
        missingo << :licence if (not o.licence.nil? and o.licence != '')
        missingo << :authoris if o.authorization_required? and !o.authorization_received
        misso = missingo.join('+').upcase
        misso = "OK" if misso == ""

        csv << [ p.name.upcase, p.surname.capitalize, p.birth.year, miss, cname, t.plate,
                 o.name.upcase, o.surname.capitalize, o.birth.year, misso
        ]
      end
    end

    respond!(csv_string, 200, 'Content-Type' => 'text/csv')
  end
  
  def csv_export_all
    csv_string = CSV.generate do |csv|

      csv << [ "Nom", "Prénom", "ADN", "Manquant", "Catégorie", "Plaque", "Nom Part", "Prenom Part", "ADN Part"]

      Profile.order_by(:name).each do |p|
        u = User[p.user_id]
        next unless u
        next if u.superadmin or u.admin
        next unless u.team and !u.team.has_free_spot?

        missing = Array.new

        missing << :paiement if u.profile.payment_required? and !u.profile.payment_received
        missing << :certif if u.profile.certificate_required? and !u.profile.certificate_received
        missing << :authoris if u.profile.authorization_required? and !u.profile.authorization_received
        miss = missing.join('+').upcase
        miss = "OK" if miss == ""

        t = u.team
        next unless t
        cat = t.category
        next unless cat
        cname = cat.map { |v| v.capitalize }.join('-')
 
        other_id = (t.vtt_id == u.id ? t.route_id : t.vtt_id )
        o = User[other_id].profile


        csv << [ p.name.upcase, p.surname.capitalize, p.birth.year, miss, cname, t.plate,
          o.name.upcase, o.surname.capitalize, o.birth.year
        ]
      end
    end

    respond!(csv_string, 200, 'Content-Type' => 'text/csv')
  end

  def remind_all
    sent = 0
    User.each do |u|
      res = do_remind(u)
      sent += 1 if res and res.count > 0
    end
    
    flash[:info] = "#{sent} rappels envoyés"
    redirect_referrer
  end

  def inform_all
    sent = 0
    User.each do |u|
      sent += 1 if do_inform(u)
    end
    
    flash[:info] = "#{sent} infos envoyées"
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


    #do_remind(u).each do |what|
    #end
    
    flash[:info] = do_remind(u).join(", ")
    #flash[:info] + to_s + what.to_s

    if flash[:info]
      flash[:info] = "Rappel envoyé à #{u.email} pour : #{flash[:info]}"
    else
      flash[:info] = "Aucun rappel nécessaire"
    end

    redirect_referer
  end

  private

  def do_inform(u)
    return unless u.email =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
    MailUtils::Informer.perform_async(u.email, "#{VttRoute.options.myurl}/#{Programme.r(:index)}", user.email || "unknown")
  end

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
    else
      if u.profile.payment_required? and !u.profile.payment_received
        missing[:reglement] = Hash.new
        missing[:reglement][:element] = "nous n'avons pas reçu votre règlement"
        missing[:reglement][:message]=<<EOF
  Pour participer au challenge, vous devez vous acquiter de 15€ si vous participez en Solo
  ou de 10€ par personne si vous participez en équipe (Duo, Tandem). Merci de libeller le 
  chèque à l'ordre de "Association Sportive Saint Laurent".
EOF
      end

      if u.profile.certificate_required? and ! u.profile.certificate_received?
        missing[:certificate] = Hash.new
        missing[:certificate][:element] = "nous n'avons pas reçu votre certificat médical"
        missing[:certificate][:message]=<<EOF
  Pour participer au challenge, vous devez soit être licencié, soit nous faire parvenir un certicat médical.
EOF
      end

      if u.profile.authorization_required? and ! u.profile.authorization_received?
        missing[:authorization] = Hash.new
        missing[:authorization][:element] = "nous n'avons pas reçu l'autorisation parentale"
        missing[:authorization][:message]=<<EOF
  Les mineurs, pour participer au challenge, doivent nous faire parvenir une autorization parentale signée.
EOF
      end

      if u.team 
        if u.team.has_free_spot?
          missing[:incompleteteam] = Hash.new
          missing[:incompleteteam][:element] = "votre équipe est incomplète"
          missing[:incompleteteam][:message]=<<EOF
  Pour participer au challenge, une équipe Duo ou Tandem doit être complète. Or, il n'y a personne dans votre équipe qui effectuée
  la partie #{u.team.has_free_spot?.to_s}
EOF
        end
      else
        missing[:noteam] = Hash.new
        missing[:noteam][:element] = "vous n'appartenez à aucune équipe"
        missing[:noteam][:message]=<<EOF
  Pour participer au challenge, vous devez impérativement appartenir à une équipe, même si vous participez en Solo.
EOF
      end
    end

    if missing.count > 0
      Ramaze::Log.info "Sending reminder to #{u.email}"
      MailUtils::Reminder.perform_async(u.email, missing, "#{VttRoute.options.myurl}/#{Registrations.r(:index)}", user.email || "unknown")
    end

    missing.keys
  end
end

