# encoding: utf-8
# 005_add_team_table.rb
#
# Adds a team table and removes event column in profile
#

Sequel.migration do
  up do
    transaction do
      create_table(:teams) do
        primary_key :id
        String :name, :size => 255, :unique => true, :null => false
        String :description, :text => true
        TrueClass :handi, :default => false
        enum :race_type, :elements => ['Solo', 'Duo', 'Tandem'], :null => false
        String :event_version, :null => false
        FixNum :plate
        foreign_key :vtt_id, :users
        foreign_key :route_id, :users
      end
      alter_table(:profiles) do
        drop_column :event
      end
    end
  end

  down do
    drop_table(:teams)
    drop_table(:teams_users)
    alter_table(:profiles) do
      add_column :event, String, :size=>255, :null=>false
     end
  end
end

