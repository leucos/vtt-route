# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'
require 'ramaze/helper/user'

user = User.create(:email=> 'bonnie@example.org', :password => 'xyz')
peer = User.create(:email=> 'clyde@example.org', :password => 'xyz')

module Ramaze
  module Helper
    module UserHelper

      def logged_in?
        true
      end

      def user
        User[:email=>'bonnie@example.org']
      end

    end
  end
end

describe "The Teams controller" do
  behaves_like :rack_test

  after do
    Team.delete
  end

  should 'create a solo team' do
    post('/teams/create', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Solo',
      :vtt_id => user.id,
      :route_id => user.id,
      :event_version => '2012' }).status.should == 200

      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.success").first.text.should =~ /Equipe créée/i

      Team[:name => 'PedaleDouce'].vtt_id.should === user.id
      Team[:name => 'PedaleDouce'].route_id.should === user.id
  end

  should 'create a duo team' do
    post('/teams/create', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Duo',
      :vtt_id => user.id,
      :event_version => '2012' }).status.should == 200

      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.success").first.text.should =~ /Equipe créée/i

      Team[:name => 'PedaleDouce'].vtt_id.should === user.id
      Team[:name => 'PedaleDouce'].race_type.should === 'Duo'
  end


  should 'not create non-solo with duplicate participant' do
    post('/teams/create', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Duo',
      :vtt_id => user.id,
      :route_id => user.id,
      :event_version => '2012' }).status.should == 302

      follow_redirect!

      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert").first.text.should =~ /Vous ne pouvez pas choisir Duo et participer aux deux épreuves/i
  end

 should 'not create teams with duplicate names' do
    post('/teams/create', { 
      :name => 'PedaleDouce',
      :description => 'Our Awesome Team',
      :race_type => 'Solo',
      :vtt_id => user.id,
      :route_id => user.id,
      :event_version => '2012' }).status.should == 302

      follow_redirect!

      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert").first.text.should =~ /Cette équipe existe déjà/i
  end

 should 'not create teams without names' do
    post('/teams/create', { 
      :description => 'Our Awesome Team',
      :race_type => 'Solo',
      :vtt_id => user.id,
      :route_id => user.id,
      :event_version => '2012' }).status.should == 302

      follow_redirect!

      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert").first.text.should =~ /Cette équipe existe déjà/i
  end

  should 'join a route team slot' do
    team = Team[:name => 'PedaleDouce']
    post('/teams/join/route/#{team.id}/#{peer.id}').status.should == 200

    team.refresh
    team.vtt_id.should === user.id
    team.route_id.should === peer.id
  end

  should 'join a vtt team slot' do
    team = Teams[:name => 'PedaleDouce']
    team.vtt_id = nil
    team.save
    post('/teams/join/vtt/#{team.id}/#{peer.id}').status.should == 200

    team.refresh
    team.vtt_id.should === user.id
    team.route_id.should === peer.id
  end

  should 'forbid vtt join if slot is taken' do
    team = Team[:name => 'PedaleDouce']
    post('/teams/join/route/#{team.id}/#{peer.id}').status.should == 302

    follow_redirect!

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Cette place n'est pas libre/i
  end

  should 'swap team members' do
    post('/teams/swap/#{team.id}').status.should == 200

    Teams[:name => 'PedaleDouce'].route_id.should === user.id
    Teams[:name => 'PedaleDouce'].vtt_id.should === peer.id
  end

  should 'return a team list' do
    get('/teams/list').status.should == 200

    nok = Nokogiri::HTML(last_response.body)
    #nok.css("div.alert").first.text.should =~ /Cette place n'est pas libre/i
  end

  should "let use leave a team" do
    post('/teams/leave').status.should == 200
  end

  should "delete a team when the last participant leaves" do
    t = Team.create(:name => 'AwesomeTeam',
                :race_type => 'Duo',
                :event_version => '2012',
                :vtt_id => user.id)

    post('/teams/leave/#{t.id}').status.should == 200

    Team[:id => t.id].should.be.nil
  end
end

