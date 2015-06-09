Sequel.migration do
  up do
    create_table(:tracker_users) do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at

      String :name
      String :email
      String :initials
    end
  end

  down do
    drop_table :tracker_users
  end
end
