require "dm-migrations"
require "migration_runner"

include DataMapper::Types

migration 1, :initial do
  up do
    create_table :integrity_projects do
      column :id,         Serial
      column :name,       String,   :nullable => false
      column :permalink,  String
      column :uri,        URI,      :nullable => false
      column :branch,     String,   :nullable => false, :default => "master"
      column :command,    String,   :nullable => false, :default => "rake"
      column :public,     Boolean,                      :default  => true
      column :building,   Boolean,                      :default  => false
      column :created_at, DateTime
      column :updated_at, DateTime

      column :build_id,   Serial
      column :notifier_id,Serial
    end

    create_table :integrity_builds do
      column :id,                Serial
      column :output,            Text,     :nullable => false, :default => ""
      column :successful,        Boolean,  :nullable => false, :default => false
      column :commit_identifier, String,   :nullable => false
      column :commit_metadata,   Yaml,     :nullable => false
      column :created_at,        DateTime
      column :updated_at,        DateTime

      column :project_id,        Serial
    end

    create_table :integrity_notifiers do
      column :id,         Serial
      column :name,       String, :nullable => false
      column :config,     Yaml,   :nullable => false

      column :project_id, Serial
    end
  end

  down do
    drop_table :integrity_notifiers
    drop_table :integrity_projects
    drop_table :integrity_builds
  end
end
