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

