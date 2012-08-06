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
        return User.first
      end
    end
  end
end

User.delete
uid = User.create({ :email=> 'mb@mbnet.fr', :password => 'xyz' })
uid.profile = Profile.create ({
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
