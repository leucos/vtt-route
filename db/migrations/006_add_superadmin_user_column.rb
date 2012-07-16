# encoding: utf-8
#
# 006_add_superadmin_user_column.rb
#
# Adds a superadmin column in users table
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

