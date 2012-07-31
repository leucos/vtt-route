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
PARAMS = { :email=> 'mb@mbnet.fr', :password => 'xyz' }  

User.delete
User.create(PARAMS.reject{|k| k == 'HTTP_REFERER'} )

describe "The Registrations controller" do
  behaves_like :rack_test

  should 'display missing authorizaton for users under 18' do
    get('/registrations/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div > div > input").first[:id].should == "Autorisation parentale"
  end

/html/body/div[2]/div[2]/div/div/div/div[1]


  should 'display missing payment' do
    get('/registrations/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div > div > input").first[:id].should == "Règlement manquant"
  end

  should 'display missing team' do
    get('/registrations/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div > div > input").first[:id].should == "name"
  end

  should 'display missing certificate' do
    get('/registrations/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div > div > input").first[:id].should == "name"
  end
end
