# encoding: utf-8
# 008_add_invite_key_team.rb
#
# Adds an invite key colmumn in teams table
#

Sequel.migration do
  up do
    transaction do
      alter_table(:teams) do
        add_column :invite_key, String, :size => 255
      end
    end
  end

  down do
    alter_table(:teams) do
      drop_column :invite_key
    end
  end
end

