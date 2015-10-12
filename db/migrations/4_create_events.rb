Sequel.migration do
  change do
    create_table(:events) do
      primary_key :id
      foreign_key :stack_id
      foreign_key :service_id
      foreign_key :build_id

      DateTime :timestamp, null: false

      String :source,   null: false
      String :location, null: true
      String :type,     null: false
      String :status,   null: false
      String :message,  null: true, text: true
    end
  end
end
