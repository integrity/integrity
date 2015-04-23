Sequel.migration do
  change do
    create_table(:pancakes_units) do
      primary_key :id
      foreign_key :stack_id
      DateTime :created_at
      DateTime :updated_at

      String   :service_def,      text: true, null: false
      String   :state,            null: false
      DateTime :state_updated_at, null: false
      String   :machine_ip
      String   :port
      String   :cluster_info,     text: true, null: false

      #field :service_def,      type: Hash
      #field :state,            type: Symbol, default: :off
      #field :state_updated_at, type: Time
      #field :ip,               type: String
      #field :port,             type: Integer
      #field :info,             type: Hash
    end
  end
end
