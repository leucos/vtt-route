#
# Select which DB to use according to environment
#


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




