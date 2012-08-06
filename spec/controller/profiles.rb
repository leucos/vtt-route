# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'
require 'ramaze/helper/user'

module Ramaze
  module Helper
    module UserHelper
      def logged_in?
        true
      end
      def user
      #_would_login?(creds)
        return User.first
      end
    end
  end
end

# Post params
PARAMS = { :email=> 'mb@mbnet.fr', :password => 'xyz', 'HTTP_REFERER' => '/profiles/index' }  

User.delete
User.create(PARAMS.reject{|k| k == 'HTTP_REFERER'} )

describe "The Profiles controller" do
  behaves_like :rack_test

  #before do
    #Ramaze::Helper::UserHelper.user_login(creds)
  #end

  after do
    Profile.delete
  end

  should 'show register form' do
    get('/profiles/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div > div > input").first[:id].should == "name"
  end
    
  FORM_FIELDS = { 
    :name              => { :value => 'Cumin', :mandatory => true },
    :surname           => { :value => 'Bernard', :mandatory => true },
    :gender            => { :value => 'male', :mandatory => true },
    :"dob-day"         => { :value => 1, :mandatory => true },
    :"dob-month"       => { :value => 1, :mandatory => true },
    :"dob-year"        => { :value => 1990, :mandatory => true },
    :address1          => { :value => "Rue Lapierre", :mandatory => true },
    :address2          => { :value => "Quartier Specialized", :mandatory => false },
    :zip               => { :value => 12345, :mandatory => true },
    :city              => { :value => "Sunn", :mandatory => true },
    :country           => { :value => "Fox", :mandatory => true },
    :org               => { :value => "ASSLC", :mandatory => false },
    :licence           => { :value => 54321, :mandatory => false },
    :phone             => { :value => "01 23 45 67 89", :mandatory => true },
    :emergency_contact => { :value => "Marcel\n01 02 03 04 05", :mandatory => true },
    :accept            => { :value => true, :mandatory => true },
  }

  # Loop over mandatory fields
  FORM_FIELDS.keep_if { |fk,fv| fv[:mandatory] }.each_key do |f|
    form = FORM_FIELDS.dup
    form.delete(f)
    # Get rid of sub-hash, promote :value to first level value
    form.each_pair { |ik,iv| form[ik] = iv[:value] }

    Profile.delete
    
    should "refuse forms without a #{f} field" do
      post('/profiles/save', form, PARAMS).status.should == 302
      follow_redirect!
      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert > ul > li").first.text.should =~ /#{Profiles::FIELD_NAMES[f]}/i
    end

    Profile.delete
    should "redisplay form pre-filled when #{f} is missing" do
      post('/profiles/save', form, PARAMS).status.should == 302
      follow_redirect!
      
      nok = Nokogiri::HTML(last_response.body)
      
      form.each_pair do |k,v|
        # Passwords are not refilled
        next if k == :pass or k == :emergency_contact

        nok.xpath("//*[@id='#{k}']").first["value"].should =~ /#{v}/i
      end
    end
  end

  form = FORM_FIELDS.dup
  form.each_pair { |ik,iv| form[ik] = iv[:value] }

  # Test valid forms
  should "accept a valid form" do
    post('/profiles/save', form, PARAMS).status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").text.should =~ /Profil mis à jour/
  end
end

