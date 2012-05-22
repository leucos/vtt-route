require_relative '../helper'
require 'nokogiri'

describe "The Users controller" do
  behaves_like :rack_test

  after do
    User.delete
  end

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
    
  FORM = { 
    :email => 'some@email',
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
    :org => "ASSLC",
    :licence => 54321,
    :event => "Solo"
  }

  MANDATORY_FIELDS = { 
    :email => 'some@email',
    :pass1 => 'vtt',
    :pass2 => 'vtt',
    :name  => 'Cumin',
    :surname => 'Bernard',
    :gender => 'male',
    :"dob-day" => 1,
    :"dob-month" => 1,
    :"dob-year" => 1999,
    :address1 => "Rue Lapierre",
    :zip => 12345,
    :city => "Sunn",
    :country => "Fox",
    :event => "Solo"
  }


  MANDATORY_FIELDS.keys.each do |f|
  #[ :email ].each do |f|
    form = FORM.dup
    form.delete(f)
    #next if f =~ /pass/
    should "refuse forms without a #{f} field" do
      post('/users/save', form, { 'HTTP_REFERER' => '/users/create'}).status.should == 302
      follow_redirect!
      nok = Nokogiri::HTML(last_response.body)
      nok.css("div.alert > ul > li").first.text.should =~ /#{Users::FIELD_NAMES[f]}/i
    end

    should "redisplay form pre-filled when #{f} is missing" do
      post('/users/save', form, { 'HTTP_REFERER' => '/users/create'}).status.should == 302
      follow_redirect!
      nok = Nokogiri::HTML(last_response.body)
      form.each_pair do |k,v|
        next if k =~ /pass|gender|event|dob-.*/
#        puts "looking for //*[@id='#{k}'] to be #{v}"
        # pass are not refilled
        nok.xpath("//*[@id='#{k}']").first["value"].should =~ /#{v}/i
      end
    end
  end
end

