#
# Select which DB to use according to environment
#


case Ramaze.options.mode
when :dev, :test
  DB=Sequel.connect('sqlite://blog.db')
when :live
  DB=Sequel.mysql2(
    'mail',
    :database => '',
    :user     => '',
    :password => '')
end




