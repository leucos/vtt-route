# 003_users_and_profiles_timestamps.rb
#
# Adds timestamps to users and profiles models
#

Sequel.migration do
  change do
    alter_table(:profiles) do
      add_column :created_at, DateTime
      add_column :updated_at, DateTime
    end
    alter_table(:users) do
      add_column :created_at, DateTime
    end
  end
end

