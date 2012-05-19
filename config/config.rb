#
# Select which DB to use according to environment
#

puts "Setting Sequel DB for #{ENV['RACK_ENV']} mode"

case Ramaze.options.mode
when :dev, :test
  DB=Sequel.sqlite
when :live
  DB=Sequel.mysql2(
    'mail',
    :database => 'mail',
    :user     => 'root',
    :password => '')
end




