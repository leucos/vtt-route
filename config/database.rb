#
# Select which DB to use according to environment
#


case Ramaze.options.mode
when :dev
  DB=Sequel.connect('sqlite://vttroute-dev.db')
when :spec
  DB=Sequel.connect('sqlite://vttroute-spec.db')
when :live
  DB=Sequel.mysql2(
    'vttroute',
    :database => '',
    :user     => '',
    :password => '')
end




