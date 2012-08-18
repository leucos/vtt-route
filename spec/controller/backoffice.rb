# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'
require 'ramaze/helper/user'


module Ramaze
  module Helper
    module UserHelper
      def backoffice_logged_in?
        true
      end

      def backoffice_user
        User[:email=>'bonnie@example.org']
      end

      alias real_logged_in? logged_in?
      alias logged_in? backoffice_logged_in?

      alias real_user user
      alias user backoffice_user
    end
  end
end

me = User.create(:email=> 'bonnie@example.org', :password => 'xyz', :admin => true)
me.profile = Profile.create ({
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

describe "The Backoffice controller" do
  behaves_like :rack_test

  # Shows list of subscribers in index
  should "show list of subscribers in index for logged in admins" do
    get('/backoffice/').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("#table-subscribers").should.not.be.nil
  end

  should "not show list of subscribers in index for non admins" do
    me.admin = false
    me.save
    get('/backoffice/').status.should == 302
    nok = Nokogiri::HTML(last_response.body)
    nok.css("#table-subscribers").should.be.empty
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

describe "The Backoffice controller" do
  behaves_like :rack_test

  should "not show list of subscribers in index for non-logged" do
    get('/backoffice/').status.should == 302
    nok = Nokogiri::HTML(last_response.body)
    nok.css("#table-subscribers").should.be.empty
  end
end

me.profile.delete
me.delete

