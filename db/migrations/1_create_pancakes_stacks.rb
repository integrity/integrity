Sequel.migration do
  change do
    create_table(:pancakes_stacks) do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at

      String   :sha,              size: 40, unique: true, null: false
      DateTime :started_at
      DateTime :destroyed_at
      String   :state,            null: false
      DateTime :state_updated_at, null: false
      String   :desired_state,    null: false
      String   :pocs,             text: true
      String   :wp_database_version
      String   :services,         text: true
      #String   :history, text: true

      #field :sha,              type: String
      #field :started_at,       type: Time
      #field :destroyed_at,     type: Time
      #field :state,            type: Symbol, default: :off
      #field :state_updated_at, type: Time
      #field :desired_state,    type: Symbol
      #field :pocs,             type: Array
      #field :services,         type: Array, default: []
      #field :history,          type: Array, default: []
    end
  end
end
