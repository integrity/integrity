Sequel.migration do
  up do
    add_column :pancakes_stacks, :cargo_branch, String
  end

  down do
    drop_column :pancakes_stacks, :cargo_branch
  end
end
