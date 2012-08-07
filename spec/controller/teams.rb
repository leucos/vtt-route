# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'
require 'ramaze/helper/user'

Profile.delete
User.delete
Team.delete

module Ramaze
  module Helper
    module UserHelper
      def team_logged_in?
        true
      end

      def team_user
        User[:email=>'bonnie@example.org']
      end

      alias real_logged_in? logged_in?
      alias logged_in? team_logged_in?

      alias real_user user
      alias user team_user
    end
  end
end

# Mocking Teams#send_invite
#

class Teams
  def send_invite(*arg)
    true
  end
end

describe "The Teams controller" do
  behaves_like :rack_test

  @me = User.create(:email=> 'bonnie@example.org', :password => 'xyz')
  @me.profile = Profile.create ({
    :name              => 'Nimcu',
    :surname           => 'Dranreb',
    :gender            => 'male',
    :birth             => Date.parse("1988-1-1"),
    :address1          => "Lapierre",
    :address2          => "Specialized",
    :zip               => 12345,
    :city              => "Sunn",
    :country           => "Fox",
    :org               => "ASSLC",
    :licence           => 54321,
    :phone             => "89",
    :emergency_contact => "Marcel"
  })

  @him = User.create(:email=> 'clyde@example.org', :password => 'xyz')
  @him.profile = Profile.create ({
    :name              => 'Cumin',
    :surname           => 'Bernard',
    :gender            => 'male',
    :birth             => Date.parse("1990-1-1"),
    :address1          => "Lapierre",
    :address2          => "Specialized",
    :zip               => 12345,
    :city              => "Sunn",
    :country           => "Fox",
    :org               => "ASSLC",
    :licence           => 54321,
    :phone             => "89",
    :emergency_contact => "Marcel"
  })

  after do
    Team.delete
  end

  should 'create a solo team' do
    post('/teams/save', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Solo',
      :vtt_id => @me.id,
      :route_id => @me.id,
      :event_version => '2012' }).status.should == 302

      follow_redirect!

      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert-success").first.text.should =~ /Equipe créée/i

      Team[:name => 'PedaleDouce'].vtt_id.should === @me.id
      Team[:name => 'PedaleDouce'].route_id.should === @me.id
  end

  should 'create a duo team as VTTist' do
    post('/teams/save', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Duo',
      :part => 'VTT',
      :event_version => '2012' }).status.should == 302

      follow_redirect!
      
      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert-success").first.text.should =~ /Equipe créée/i

      Team[:name => 'PedaleDouce'].vtt_id.should === @me.id
      Team[:name => 'PedaleDouce'].race_type.should === 'Duo'
  end

 should 'create a duo team as Router' do
    post('/teams/save', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Duo',
      :part => "Route",
      :event_version => '2012' }).status.should == 302

      follow_redirect!

      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert-success").first.text.should =~ /Equipe créée/i

      Team[:name => 'PedaleDouce'].route_id.should === @me.id
      Team[:name => 'PedaleDouce'].race_type.should === 'Duo'
  end

 should 'create a tandem team' do
    post('/teams/save', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Tandem',
      :route_id => @me.id,
      :event_version => '2012' }).status.should == 302

      follow_redirect!
      
      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert-success").first.text.should =~ /Equipe créée/i

      Team[:name => 'PedaleDouce'].vtt_id.should === @me.id
      Team[:name => 'PedaleDouce'].race_type.should === 'Tandem'
  end

 should 'not create teams with duplicate names' do
    Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
        :handi => false, :race_type => "Solo", 
        :event_version => "2012", :vtt_id => @me.id})
    post('/teams/save', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Solo',
      :vtt_id => @me.id,
      :route_id => @me.id,
      :event_version => '2012' }).status.should == 302
      
      follow_redirect!

      #puts last_response.body
      
      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert").first.text.should =~ /Ce nom d'équipe est déjà utilisé/i
  end

 should 'not create teams without names' do
    post('/teams/save', { 
      :description => 'Our Awesome Team',
      :race_type => 'Solo',
      :vtt_id => @me.id,
      :route_id => @me.id,
      :event_version => '2012' }).status.should == 302

      follow_redirect!

      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert").first.text.should =~ /Ce champ doit être renseigné/i
  end

  should 'join a route team slot' do
    team = Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
        :handi => false, :race_type => "Solo", 
        :event_version => "2012", :vtt_id => @me.id})

    post("/teams/join/route/#{team.id}/#{@him.id}").status.should == 200
    
    team.refresh

    team.vtt_id.should === @me.id
    team.route_id.should === @him.id
  end

  should 'join a vtt team slot' do
    team = Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
        :handi => false, :race_type => "Solo", 
        :event_version => "2012", :route_id => @me.id})  

    post("/teams/join/vtt/#{team.id}/#{@him.id}").status.should == 200

    team.refresh

    team.vtt_id.should === @him.id
    team.route_id.should === @me.id
  end

  should 'not join a wtf team slot' do
    team = Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
        :handi => false, :race_type => "Solo", 
        :event_version => "2012", :route_id => @me.id})  

    post("/teams/join/wtf/#{team.id}/#{@him.id}").status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-error").text.should =~ /Type d'épreuve inconnue/
  end

  should 'forbid vtt join if slot is taken' do
    team = Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
        :handi => false, :race_type => "Solo", 
        :event_version => "2012", :vtt_id => @me.id})

    post("/teams/join/vtt/#{team.id}/#{@him.id}").status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Cette place est déjà prise/i
  end

  should 'forbid route join if slot is taken' do
    team = Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
        :handi => false, :race_type => "Solo", 
        :event_version => "2012", :route_id => @me.id})

    post("/teams/join/route/#{team.id}/#{@him.id}").status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Cette place est déjà prise/i
  end

  should 'swap team members' do
    team = Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
      :handi => false, :race_type => "Solo", 
      :event_version => "2012", 
      :vtt_id => @me.id,
      :route_id => @him.id})

    post("/teams/swap/#{team.id}").status.should == 302

    team.refresh
    team.route_id.should === @me.id
    team.vtt_id.should === @him.id
  end

  #should 'return a team list' do
  #  get('/teams/list').status.should == 200

  #  nok = Nokogiri::HTML(last_response.body)
    #nok.css("div.alert").first.text.should =~ /Cette place n'est pas libre/i
  #end

  should "let a user leave a team" do
    team = Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
      :handi => false, :race_type => "Duo", 
      :event_version => "2012", 
      :vtt_id => @me.id,
      :route_id => @him.id})

    post("/teams/leave/#{team.id}").status.should == 302
  end

  should "delete a team when the solo participant leaves" do
    team = Team.create({:name=>"PedaleDouce", :description => "Pedalors", 
      :handi => false, :race_type => "Solo", 
      :event_version => "2012", 
      :vtt_id => @me.id,
      :route_id => @him.id})

    post("/teams/leave/#{team.id}").status.should == 302
  end

  should "delete a team when the last participant leaves" do
    t = Team.create(:name => 'AwesomeTeam',
                :race_type => 'Duo',
                :event_version => '2012',
                :vtt_id => @me.id)

    get("/teams/leave/#{t.id}").status.should == 302

    Team[:id => t.id].should.be.nil
  end

  should "be able to invite a friend" do
    t = Team.create(:name => 'AwesomeTeam',
                :race_type => 'Duo',
                :event_version => '2012',
                :vtt_id => @me.id)

    post("/teams/invite/#{t.id}", { :email => @him.email }).status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /L'invitation à bien été envoyée/i
  end

  should "not be able to invite Mr Nobody" do
    t = Team.create(:name => 'AwesomeTeam',
                :race_type => 'Duo',
                :event_version => '2012',
                :vtt_id => @me.id)

    post("/teams/invite/#{t.id}").status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Désolé, je ne connais personne à cette adresse/i
  end

  should "be able to confirm an invite" do
    t = Team.create(:name => 'AwesomeTeam',
                :race_type => 'Duo',
                :event_version => '2012',
                :invite_key => '1234',
                :vtt_id => @me.id)

    get("/teams/confirm/#{@him.email}/#{t.id}/1234").status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Félicitations, vous avez été ajouté à l'équipe/i
  end

  should "not be able to invite a friend without a valid invite" do
    t = Team.create(:name => 'AwesomeTeam',
                :race_type => 'Duo',
                :event_version => '2012',
                :vtt_id => @me.id)

    get("/teams/confirm/wtfemail/#{t.id}/4321").status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Pas d'invitation à ce numéro/i
  end

  should "not be able to invite a friend without a valid email" do
    t = Team.create(:name => 'AwesomeTeam',
                :race_type => 'Duo',
                :event_version => '2012',
                :invite_key => '1234',
                :vtt_id => @me.id)

    get("/teams/confirm/wtfemail/#{t.id}/1234").status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Pas d'invitation pour cet email/i
  end

  should "not be able to invite a friend in a full team" do
    t = Team.create(:name => 'AwesomeTeam',
                :race_type => 'Duo',
                :event_version => '2012',
                :invite_key => '1234',
                :vtt_id => @me.id,
                :route_id => @me.id)

    get("/teams/confirm/#{@him.email}/#{t.id}/1234").status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Désolé, la place est prise/i
  end

  # Refuses solo for yob > 1995
  # should "refuse solo event for users born after 1995" do
  #   form[:"dob-year"] = 1996
  #   post('/profiles/save', form, PARAMS).status.should == 302
  #   follow_redirect!
  #   nok = Nokogiri::HTML(last_response.body)
  #   nok.css("div.alert").text.should =~ /Impossible de participer en Solo pour les moins de 17 ans/
  # end

  # # Refuses solo for yob > 1995
  # should "accept solo event for users born before or in 1995" do
  #   form[:"dob-year"] = 1995
  #   post('/profiles/save', form, PARAMS).status.should == 302
  #   follow_redirect!
  #   nok = Nokogiri::HTML(last_response.body)
  #   nok.css("div.alert").text.should =~ /Profil mis à jour/
  # end

end

module Ramaze
  module Helper
    module UserHelper
      alias logged_in? real_logged_in?
      alias user real_user
    end
  end
end
