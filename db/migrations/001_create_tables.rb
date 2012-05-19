Sequel.migration do
  up do
    create_table(:users) do
      String :name, :null => false, :primary_key => true
      String :surname, :null => false, :index => true
      String :gender, :size => 1, :null => false, :index => true
      Date   :birth, :null => false
      String :address1, :null => false
      String :address2
      String :zip, :null => false
      String :city, :null => false
      String :country, :null => false
      String :phone
      String :org
      String :licence
      String :event, :null => false
      String :peer, :index => true
    end
  end
  down do
    drop_table(:users)
  end
end
