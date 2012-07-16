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
        User[:email=>'bonnie@example.org']
      end

      alias real_logged_in? logged_in?
      alias logged_in? team_logged_in?

      alias real_user user
      alias user team_user
    end
  end
end


describe "The Backoffice controller" do
  behaves_like :rack_test

  # Shows list of subscribers in index
  should "show list of subscribers in index" do
    get('/backoffice/').status.should == 200
  #  nok = Nokogiri::HTML(last_response.body)
  #  nok.css("form").attribute('action').value.should == "/users/login"
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