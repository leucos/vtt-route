# coding: utf-8

class Statistics < Controller

  def index
    u = User.filter(:admin=>false, :superadmin=>false).select(:id)
    @equipes = Team.count
    @inscrits = u.count
    @subtitle = "#{@inscrits} inscrits - #{@equipes} équipes"

    @stats = Hash.new

    begin
      @stats[:people_in_teams] = { :count => Team.where(:vtt_id => nil).count + Team.exclude(:route_id => nil).count }
      @stats[:people_in_teams][:percent] = 100 * @stats[:people_in_teams][:count] / @inscrits
      #@avancement = 100*(Team.where(:vtt_id => nil).count + Team.exclude(:route_id => nil).count)/@inscrits 
    rescue ZeroDivisionError
      @stats[:people_in_teams][:percent] = 100
    end

    begin
      @stats[:people_paid] = { :count => Profile.where(:payment_received => true).count  }
      @stats[:people_paid][:percent] = 100 * @stats[:people_paid][:count] / @inscrits
      #@avancement = 100*(Team.where(:vtt_id => nil).count + Team.exclude(:route_id => nil).count)/@inscrits 
    rescue ZeroDivisionError
      @stats[:people_paid][:percent] = 100
    end

    begin
      p = Profile.where(:user_id => u)

      @stats[:people_with_profile] = { :count => p.count }
      @stats[:people_with_profile][:percent] = 100 * @stats[:people_with_profile][:count] / @inscrits
      #@avancement = 100*(Team.where(:vtt_id => nil).count + Team.exclude(:route_id => nil).count)/@inscrits 
    rescue ZeroDivisionError
      @stats[:people_with_profile][:percent] = 0
    end

    @stats[:teams] = Hash.new
    tc = Team.group_and_count(:race_type).all
    tc.map { |x| @stats[:teams][x[:race_type].downcase.to_sym] = x[:count] }  

    @stats[:teams_stats] = Hash.new
    [:solo, :duo, :tandem].each do |k|
      @stats[:teams_stats][k] = { :count => @stats[:teams][k] } rescue 0
      @stats[:teams_stats][k][:percent] = 100 * @stats[:teams][k]/@equipes rescue 0
    end

    @stats[:subscription_flotr] = Array.new
    #@stats[:subscription_dates] = DB.fetch("select date_format(created_at,'%Y-%m-%d') as dte,count(*) as cnt from users group by date_format(created_at,'%Y-%m-%d')").all
    @stats[:subscription_dates] = DB.fetch("select dayofyear(created_at) as dte,count(*) as cnt from users where admin=FALSE and superadmin=FALSE group by dayofyear(created_at)").all
    @stats[:subscription_dates].each do |v|
      @stats[:subscription_flotr] << [ v[:dte], v[:cnt] ]
    end

    @stats[:categories] = Hash.new

    # Compute cats
    Team.each do |t|
      cat = t.category
      next unless cat

      name = cat.sort.map { |v| v.capitalize }.join
      @stats[:categories][name] += 1 rescue @stats[:categories][name] = 1
    end

    Ramaze::Log.debug @stats.inspect
  end
  
end


