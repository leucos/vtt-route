# encoding: UTF-8
#
require_relative '../helper'
require 'nokogiri'
require 'ramaze/helper/user'

class Users
  def send_confirmation_email(*args)
    true
  end

  def send_reset_email(*args)
    true
  end  
end

#User.delete
#User.create(PARAMS.reject{|k| k == 'HTTP_REFERER'} )

describe "The Users controller" do
  behaves_like :rack_test

  #before do
    #Ramaze::Helper::UserHelper.user_login(creds)
  #end

 # after do
 #   Profile.delete
 # end

  # Index redirects to login
  should "redirect to login on index" do
    get('/users/').status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("form").attribute('action').value.should == "/users/login"
  end

  # Show a creation form
  should "show registration form" do
    get('/users/create').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("form").attribute('action').value.should == "/users/save"
  end

  # Issues a logout
  should "be able to logout" do
    get('/users/logout').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-success").text.should =~ /Déconnecté/

    # Show login form at /users/login/
    get('/users/login').status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("form").attribute('action').value.should == "/users/login"    
  end

  # Saves new users
  should "save users" do
    post('/users/save', { :email => 'dookie@example.org', 
                          :pass1 => 'wookie', 
                          :pass2 => 'wookie'} ).status.should == 200
    User[:email => 'dookie@example.org'].should.not.be.nil
    User[:email => 'dookie@example.org'].delete
  end

  # Let users confirm keys
  should "let users confirm keys" do
    u = User.create(:email => 'dookie@example.org', :password => 'wookie')
    get("/users/confirm/#{u.confirmation_key}").status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("h2#subtitle").text.should == 'Votre compte est validé'
    u.delete
  end

  # Complain about unknwon confirmation keys
  should "complain on unknown confirmation keys" do
    get("/users/confirm/1234567").status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-error").text.should =~ /Ce numéro de confirmation n'existe pas/
  end

  # Let users ask password reset
  should "send password resets" do
    u = User.create(:email => 'dookie@example.org',
                    :password => 'wookie',
                    :confirmed => true)

    post('/users/ask_reset', { :email => 'dookie@example.org' }).status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-success").text.should =~ /Veuillez vérifier votre messagerie pour réinitialiser votre mot de passe/
    u.delete
  end

  # Complain if email isn't known
  should "complain for password resets asked for unknown emails" do
    post('/users/ask_reset', { :email => 'dookie@example.org' }).status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-error").text.should =~ /Désolé, cet email n'existe pas/
  end

  # Complain if account isn't validated yet
  should "complain for password resets asked for unconfirmed account" do
     u = User.create(:email => 'dookie@example.org',
                     :password => 'wookie',
                     :confirmed => false)

    post('/users/ask_reset', { :email => 'dookie@example.org' }).status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-error").text.should =~ /Désolé, vous n'avez pas confirmé votre compte/
    u.delete
  end

  # Let users confirm password resets
  should "let users confirm password resets" do
    u = User.create(:email => 'dookie@example.org', :password => 'wookie', :confirmed => true)
    get("/users/lost_password/#{u.confirmation_key}").status.should == 200
    nok = Nokogiri::HTML(last_response.body)
    nok.css("h2#subtitle").text.should == 'Entrez votre nouveau mot de passe'
    u.delete
  end

  # Complain about unknown password resets
  should "complain on unknown password resets" do
    get("/users/lost_password/1234567").status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-error").text.should =~ /Ce numéro de validation n'existe pas/
  end

  # Let user reset their password
  should "accept new reset password" do
     u = User.create(:email => 'dookie@example.org',
                     :password => 'wookie',
                     :confirmed => true,
                     :confirmation_key => '12345')

    post('/users/do_reset', { :email => u.email,
                              :key => u.confirmation_key,
                              :pass1 => 'wookie',
                              :pass2 => 'wookie' }).status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-success").text.should =~ /Modification effectuée. Vous pouvez vous connecter./
    u.delete
  end

  # Refuse new passwords if they don't match
  should "refuse new password if they don't match" do
     u = User.create(:email => 'dookie@example.org',
                     :password => 'wookie',
                     :confirmed => true,
                     :confirmation_key => '12345')

    post('/users/do_reset', { :email => u.email,
                              :key => u.confirmation_key,
                              :pass1 => 'wookie',
                              :pass2 => 'wikooe' }).status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-error").text.should =~ /Les mots de passe ne correspondent pas./
    u.delete
  end

  # Handle resets for non-existent users properly
  should "complain gracefully when asked to reset password for unknown user" do
    post('/users/do_reset', { :email => 'wrong@example.com',
                              :key => 'no such key exists',
                              :pass1 => 'wookie',
                              :pass2 => 'wookie' }).status.should == 302
    follow_redirect!
    nok = Nokogiri::HTML(last_response.body)
    nok.css("div.alert-error").text.should =~ /Ooops, quelque chose s'est très mal passé... J'ai prévenu le responsable./
  end

end

