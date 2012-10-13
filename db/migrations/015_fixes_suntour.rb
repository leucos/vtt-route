# encoding: utf-8
#
# 015_fixes_suntour.rb
#
# Fixes url
#

Sequel.migration do
  change do
    transaction do
      self[:sponsors].where(:name => 'Sa Suntour').update(:name => 'SR Suntour')
   end
  end
end

