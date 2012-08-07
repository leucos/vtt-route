# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'
require 'ramaze/helper/user'

describe "The Controller base controller" do
  behaves_like :rack_test

  should "show custom 404" do
    get("/omg_this_page_doesnt_exist").status.should == 200

    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert").first.text.should =~ /Désolé, cette page n'existe pas/i
  end
end
