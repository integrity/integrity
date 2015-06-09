Sequel.migration do
  up do
    create_table(:tracker_stories) do
      primary_key :id
      DateTime    :created_at
      DateTime    :updated_at
      String      :url
      Integer     :project_id
      Text        :name
      String      :type
      String      :current_state
      String      :commit_state
    end

    add_column :integrity_branches, :story_id, Integer
  end

  down do
    drop_table :tracker_stories
    remove_column :integrity_branches, :story_id
  end
end
