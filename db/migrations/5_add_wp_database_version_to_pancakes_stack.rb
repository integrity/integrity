Sequel.migration do
  up do
    add_column :pancakes_stacks, :wp_database_version, String
  end

  down do
    drop_column :pancakes_stacks, :wp_database_version
  end
end
