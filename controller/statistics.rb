# coding: utf-8

class Statistics < Controller

  def index
    u = User.filter(:admin=>false, :superadmin=>false).select(:id)
    @equipes = Team.count
    @inscrits = u.count
    @subtitle = "#{@inscrits} inscrits - #{@equipes} équipes"

    @stats = Hash.new

    begin
      count = Team.where(:race_type => "Solo").count +
      Team.exclude(:race_type => "Solo").exclude(:route_id => nil).count +
      Team.exclude(:race_type => "Solo").exclude(:vtt_id => nil).count

      @stats[:people_in_teams] = { :count => Team.where(:vtt_id => nil).count + Team.exclude(:route_id => nil).count }
      @stats[:people_in_teams][:percent] = 100 * @stats[:people_in_teams][:count] / @inscrits
    rescue ZeroDivisionError
      @stats[:people_in_teams][:percent] = 100
    end

    begin
      @stats[:people_paid] = { :count => Profile.where(:payment_received => true).count  }
      @stats[:people_paid][:percent] = 100 * @stats[:people_paid][:count] / @inscrits
    rescue ZeroDivisionError
      @stats[:people_paid][:percent] = 100
    end

    begin
      p = Profile.where(:user_id => u)

      @stats[:people_with_profile] = { :count => p.count }
      @stats[:people_with_profile][:percent] = 100 * @stats[:people_with_profile][:count] / @inscrits
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
    @stats[:subscription_dates] = DB.fetch("select dayofyear(created_at) as dte,count(*) as cnt from users where admin=FALSE and superadmin=FALSE group by dayofyear(created_at)").all
    @stats[:subscription_dates].each do |v|
      @stats[:subscription_flotr] << [ v[:dte], v[:cnt] ]
    end

    @stats[:age_flotr] = Array.new
    @stats[:age_dates] = DB.fetch("select year(now())-year(birth) as age, count(*) as cnt from profiles where year(birth) > 1900 group by age").all
    @stats[:age_dates].each do |v|
      @stats[:age_flotr] << [ v[:age], v[:cnt] ]
    end

    @stats[:categories] = Hash.new

    # Compute cats
    Team.each do |t|
      cat = t.category
      next unless cat

      name = cat.map { |v| v.capitalize }.join('-')
      @stats[:categories][name] += 1 rescue @stats[:categories][name] = 1
    end

    @stats[:complete_teams] = 0
    @stats[:categories].each_pair do |k,v|
      @stats[:complete_teams] += v
    end

  end
  
end


