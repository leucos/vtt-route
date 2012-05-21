require_relative '../helper'
require 'nokogiri'

FORM = { 
  :email => '',
  :pass1 => 'vtt',
  :pass2 => 'vtt',
  :name  => 'Cumin',
  :surname => 'Bernard',
  :gender => 'male',
  :"dob-day" => 1,
  :"dob-month" => 1,
  :"dob-year" => 1999,
  :address1 => "Rue Lapierre",
  :address2 => "Quartier Specialized",
  :zip => 12345,
  :city => "Sunn",
  :country => "Fox",
  :event => "Solo"
}

describe "The Users controller" do
  behaves_like :rack_test

  should 'show login or register choice' do
    get('/users/index').status.should == 200
    last_response.body.should =~ /inscrire/
    last_response.body.should =~ /connecter/
  end

  should 'show register form' do
    get('/users/create').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div > div > input").first[:id].should == "email"
  end
  
#  should 'refuse forms without an email' do
#    form = FORM
#    form.delete(:email)
#    post('/users/save', form).status.should == 302
#  end
end



