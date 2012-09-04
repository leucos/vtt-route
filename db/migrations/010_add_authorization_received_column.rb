# encoding: utf-8
# 010_add_authorization_received_column.rb
#
# Adds an authorization_received column in profiles table
#

Sequel.migration do
  change do
    transaction do
      alter_table(:profiles) do
        add_column :authorization_received, TrueClass, :default=>false
      end
    end
  end
end

