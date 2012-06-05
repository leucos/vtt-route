# 002_emergency_contact.rb
#
# Adds emergency contact to profile
#

Sequel.migration do
  change do
    alter_table(:profiles) do
      add_column :emergency_contact, String, :text => true
    end
  end
end

