Sequel.migration do
  change do
    create_table(:pancakes_commits) do
      primary_key :id
      foreign_key :stack_id
      DateTime :created_at
      DateTime :updated_at

      String :sha,        size: 40, null: false
      String :author,     null: false
      String :message,    text: true, null: false
      DateTime :date,     null: false
      String :branch
      String :repo
      TrueClass :locked,  null: false, default: false
      TrueClass :at_head, null: false, default: false

      #field :sha,     type: String
      #field :author,  type: String
      #field :message, type: String
      #field :date,    type: String
      #field :branch,  type: String
      #field :repo,    type: String
      #field :locked,  type: Boolean, default: false
      #field :at_head, type: Boolean, default: false
    end
  end
end
