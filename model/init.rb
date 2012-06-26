# This file is used for loading all your models. Note that you don't have to actually use
# this file. The great thing about Ramaze is that you're free to change it the way you see
# fit.

# Here go your requires for models:

Sequel.extension(:pagination)


# The migration extension is needed in order to run migrations.
Sequel.extension(:migration)

# Migrate the database
Sequel::Migrator.run(DB, __DIR__('../db/migrations'))

require 'bcrypt'
require 'securerandom'

# Require settings
Ramaze::Log.debug("Requiring models")

Dir.glob('model/*.rb').each do |file|
 file = file.match(/model\/(.*)\.rb/)[1]
  next if file == "init"
  Ramaze::Log.debug("Loading model #{file}")
  require __DIR__(file)
end
