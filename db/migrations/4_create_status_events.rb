Sequel.migration do
  change do
    create_table(:status_events) do
      primary_key :id
      foreign_key :stack_id
      foreign_key :service_id

      DateTime :created_at, null: false
      DateTime :updated_at

      String :source,         null: false
      String :code_location,  null: true
      String :log_location,   null: true
      String :type,           null: false
      String :status,         null: false
      String :message, text: true, null: true
    end
  end
end
