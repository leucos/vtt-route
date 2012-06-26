# 005_users_superadmin_column.rb
#
# Adds timestamps to users and profiles models
#

Sequel.migration do
  change do
    alter_table(:users) do
      add_column :superadmin, TrueClass
    end
  end
end

