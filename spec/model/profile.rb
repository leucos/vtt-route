# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'

uid = User.create(:email => 'who@example.org', :password => '42')

describe "The Profile model" do
  should "Add timestamp on create" do
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

    uid.profile.created_at.should.not.be.nil
  end

  should "update timestamp on save" do
    uid.profile.name = "DrBike"
    uid.profile.save
    uid.profile.updated_at.should.not.be.nil
  end

  should "tell when a certificate is required when unlicenced" do
    uid.profile.federation = "Non licencié"
    uid.profile.licence = nil
    uid.profile.save

    uid.profile.certificate_required?.should.be.true
  end

  should "tell a certificate is required when licence has no number" do
    uid.profile.federation = "Bikers"
    uid.profile.licence = nil
    uid.profile.save

    uid.profile.certificate_required?.should.be.true
  end
  
  should "tell a certificate is required when profile has no licence but has number" do
    uid.profile.federation = "Non licencié"
    uid.profile.licence = 42
    uid.profile.save

    uid.profile.certificate_required?.should.be.true
  end
  
  should "tell a certificate is not required when profile licence and number" do
    uid.profile.federation = "Bikers"
    uid.profile.licence = 42
    uid.profile.save

    uid.profile.certificate_required?.should.be.false
  end
  
  should "tell an authorizaton is required when age at event is below 18" do
    uid.profile.birth = EVENT_DATE - 18.years + 1.day
    uid.profile.save

    uid.profile.authorization_required?.should.be.true
  end


  should "tell an authorizaton is required when age at event is over 18" do
    uid.profile.birth = EVENT_DATE - 18.years
    uid.profile.save

    uid.profile.authorization_required?.should.be.false
  end
end

uid.profile.delete
uid.delete

# TODO : test validations
# def validate
#   super
#   validates_presence [:name, :surname, :address1, :zip, :city, :country,
#                       :phone, :gender, :birth, :emergency_contact ],
#                       :message => 'Ce champ doit être renseigné'
#   validates_exact_length 5, :zip, :message => 'Ce code postal est invalide'
# end
