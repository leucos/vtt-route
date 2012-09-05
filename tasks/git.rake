# encoding: utf-8
#
# Git tasks 
#
namespace :git do
  desc "Pulls latest from master"
  task :pull do
    system("git pull")
  end
  desc "Show current version"
  task :version do
    system("git describe --always --tag")
  end
end
