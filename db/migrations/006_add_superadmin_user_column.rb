# encoding: utf-8
# 005_add_team_table.rb
#
# Adds a team table and removes event column in profile
#

Sequel.migration do
  up do
    transaction do
      alter_table(:users) do
        add_column :superadmin, TrueClass, :default => false
      end
    end
  end

  down do
    alter_table(:profiles) do
      drop_column :superadmin
    end
  end
end

