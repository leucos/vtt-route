require 'ramaze'
require 'ramaze/spec/bacon'

require File.expand_path('../../app', __FILE__)

puts "Running specs using database #{DB.opts[:database]}\n"

DB.tables.each do |t|
  DB[t].delete unless t == :schema_info
end

