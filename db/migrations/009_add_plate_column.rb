# encoding: utf-8
# 009_add_plate_column.rb
#
# Adds a plate column in teams table
#

Sequel.migration do
  up do
    transaction do
      alter_table(:teams) do
        drop_column :plate
        add_column :plate, Fixnum
      end
    end
  end

  down do
    alter_table(:teams) do
      drop_column :plate
    end
  end
end

