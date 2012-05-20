#
# Select which DB to use according to environment
#


case Ramaze.options.mode
when :dev, :test
  DB=Sequel.connect('sqlite://vttroute.db')
when :live
  DB=Sequel.mysql2(
    'vttroute',
    :database => '',
    :user     => '',
    :password => '')
end




