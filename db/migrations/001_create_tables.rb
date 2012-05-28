Sequel.migration do
  up do
    create_table(:participants, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :user_id, :users
      
      String :name, :size=>255, :null=>false
      String :surname, :size=>255, :null=>false
      String :gender, :size=>1, :null=>false
      Date   :birth, :null=>false
      String :address1, :size=>255, :null=>false
      String :address2, :size=>255
      String :zip, :size=>255, :null=>false
      String :city, :size=>255, :null=>false
      String :country, :default=>"France", :size=>255, :null=>false
      String :phone, :size=>255
      String :org, :size=>255
      String :licence, :size=>255
      String :event, :size=>255, :null=>false
      String :peer, :size=>255
      TrueClass :payment_received, :default=>false
      TrueClass :certificate_received, :default=>false

      index [:email]
      index [:gender]
      index [:peer]
      index [:surname]
    end

    create_table(:users) do
      primary_key :id
      foreign_key :participant_id, :users

      String :email, :size => 255, :null => false
      String :password_hash, :size => 255, :null => false
      String :confirmation_key, :size => 255
      TrueClass :confirmed, :default => false
      TrueClass :admin, :default => false
    end
  end
  
  down do
    drop_table(:users, :schema_info)
    drop_table(:participants, :schema_info)
  end
end
