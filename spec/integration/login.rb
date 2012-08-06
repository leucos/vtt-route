# encoding: UTF-8
#

require_relative '../helper'
require 'capybara'
require 'capybara/dsl'
#require 'capybara-screenshot'

# module Bacon
#   module SpecDoxCapybaraScreenshotOutput
#     include SpecDoxOutput

#     def handle_requirement(description)
#       print "- #{description}"
#       error = yield
#       if !error.empty? 
#         if Capybara::Screenshot.autosave_on_failure
#           filename_prefix = Capybara::Screenshot.filename_prefix_for(:bacon, description)
#           saver = Capybara::Screenshot::Saver.new(Capybara, Capybara.page, true, filename_prefix)
#           saver.save
#           Counter[:screenshots]+=1
#           puts "Saved in #{saver.screenshot_path}"
#         end
#         print " [#{error}]"
#       end
#       puts
#     end

#     def handle_summary
#       print ErrorLog  if Backtraces
#       puts "%d specifications (%d requirements), %d failures, %d errors, %d screenshots taken" %
#       Counter.values_at(:specifications, :requirements, :failed, :errors, :screenshots)
#       puts "(screenshots saved in %s)" % Capybara::Screenshot.capybara_root if Counter[:screenshots]
#     end
#   end
# end

#Bacon.extend(Bacon::SpecDoxCapybaraScreenshotOutput)
Bacon.extend(Bacon::SpecDoxOutput)

Capybara.configure do |c|
  c.default_driver = :selenium
  c.app            = Ramaze.middleware
  c.save_and_open_page_path = File.join(Ramaze.options.roots.first, 'tmp/')
end

shared :capybara do
  Ramaze.setup_dependencies
  extend Capybara::DSL
end

describe 'Testing Ramaze' do
  behaves_like :capybara

  it 'Go to the homepage' do
    visit '/'
    page.has_content?('Inscriptions').should == true
  end


  it 'Logs in' do
    User.create(:email=> 'mb@mbnet.fr', :password => 'xyz', :confirmed => true)

    visit '/users/login'
    fill_in 'Email', :with => 'mb@mbnet.fr'
    fill_in 'Mot de passe', :with => 'xyz'
    
   # Capybara::Screenshot.screen_shot_and_save_page

    click_button 'connect'

    page.current_path.should == '/profiles/index'
    page.has_content?('Profil').should == true
  end
end
