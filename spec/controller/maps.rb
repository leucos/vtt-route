# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'

describe "The Maps controller" do
  behaves_like :rack_test

  # Shows list of maps
  should "show list of maps" do
    get('/maps/').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("#map_canvas").should.not.be.nil
  end

end
