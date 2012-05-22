Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      String :email, :null => false, :unique => true, :index => true
      String :password_hash, :null => false
      String :name, :null => false, :null => false
      String :surname, :null => false, :index => true
      String :gender, :size => 1, :null => false, :index => true
      Date   :birth, :null => false
      String :address1, :null => false
      String :address2
      String :zip, :null => false
      String :city, :null => false
      String :country, :null => false, :default => "France"
      String :phone
      String :org
      String :licence
      String :event, :null => false
      String :peer, :index => true
      TrueClass :confirmed, :default => false
      TrueClass :payment_received, :default => false
      TrueClass :certificate_received, :default => false
      String :confirmation_key, :default => nil
    end
  end
  down do
    drop_table(:users)
  end
end
