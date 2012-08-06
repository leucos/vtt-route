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

describe "The Teams controller" do
  behaves_like :rack_test

  @me = User.create(:email=> 'bonnie@example.org', :password => 'xyz')
  @me.refresh
  @him = User.create(:email=> 'clyde@example.org', :password => 'xyz')
  @him.refresh


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

  should 'create a duo team' do
    post('/teams/save', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Duo',
      :vtt_id => @me.id,
      :event_version => '2012' }).status.should == 302

      follow_redirect!
      
      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert-success").first.text.should =~ /Equipe créée/i

      Team[:name => 'PedaleDouce'].vtt_id.should === @me.id
      Team[:name => 'PedaleDouce'].race_type.should === 'Duo'
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

    post("/teams/leave/#{t.id}").status.should == 302

    Team[:id => t.id].should.be.nil
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
