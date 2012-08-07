# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'
require 'ramaze/helper/user'

module Ramaze
  module Helper
    module UserHelper
      def team_logged_in?
        true
      end

      def team_user
        User.first
      end

      alias real_logged_in? logged_in?
      alias logged_in? team_logged_in?

      alias real_user user
      alias user team_user
    end
  end
end

User.delete
uid = User.create({ :email=> 'mb@mbnet.fr', :password => 'xyz' })
uid.profile = Profile.create ({
  :name              => 'Cumin',
  :surname           => 'Bernard',
  :gender            => 'male',
  :birth             => Date.parse("1998-1-1"),
  :address1          => "Lapierre",
  :address2          => "Specialized",
  :zip               => 12345,
  :city              => "Sunn",
  :country           => "Fox",
  :org               => nil,
  :licence           => nil,
  :phone             => "89",
  :emergency_contact => "Marcel"
      })

describe "The Registrations controller" do
  behaves_like :rack_test

  should 'display missing authorizaton for users under 18' do
    get('/registrations/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div#div-authorization.alert-error").should.not.be.nil
  end

  should 'display missing payment' do
    get('/registrations/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div#div-payment.alert-error").should.not.be.nil
  end

  should 'display missing team' do
    get('/registrations/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div#div-team.alert-error").should.not.be.nil
  end

  should 'display missing certificate' do
    get('/registrations/index').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div#div-certificate.alert-error").should.not.be.nil
  end
end

module Ramaze
  module Helper
    module UserHelper
      alias logged_in? real_logged_in?
      alias user real_user
    end
  end
end

