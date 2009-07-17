require "dm-migrations"
require "migration_runner"

module Integrity
  def self.migrate_db
    setup_initial_migration if pre_migrations?
    Integrity::Migrations.migrate_up!
  end

  def self.setup_initial_migration
    database_adapter.execute %q(CREATE TABLE "migration_info" ("migration_name" VARCHAR(255));)
    database_adapter.execute %q(INSERT INTO "migration_info" ("migration_name") VALUES ("initial"))
  end

  def self.pre_migrations?
    !table_exists?("migration_info") &&
      ( table_exists?("integrity_projects") &&
        table_exists?("integrity_builds")   &&
        table_exists?("integrity_notifiers") )
  end

  def self.table_exists?(table_name)
    database_adapter.storage_exists?(table_name)
  end

  def self.database_adapter
    DataMapper.repository(:default).adapter
  end

  module Migrations
    # This is what is actually happening:
    # include DataMapper::MigrationRunner

    include DataMapper::Types

    migration 1, :initial, :verbose => true do
      up do
        create_table :integrity_projects do
          column :id,          Integer,  :serial => true
          column :name,        String,   :nullable => false
          column :permalink,   String
          column :uri,         URI,      :nullable => false
          column :branch,      String,   :nullable => false, :default => "master"
          column :command,     String,   :nullable => false, :default => "rake"
          column :public,      Boolean,                      :default  => true
          column :building,    Boolean,                      :default  => false
          column :created_at,  DateTime
          column :updated_at,  DateTime

          column :build_id,    Integer
          column :notifier_id, Integer
        end

        create_table :integrity_builds do
          column :id,                Integer,  :serial => true
          column :output,            Text,     :nullable => false, :default => ""
          column :successful,        Boolean,  :nullable => false, :default => false
          column :commit_identifier, String,   :nullable => false
          column :commit_metadata,   Yaml,     :nullable => false
          column :created_at,        DateTime
          column :updated_at,        DateTime

          column :project_id,        Integer
        end

        create_table :integrity_notifiers do
          column :id,         Integer, :serial => true
          column :name,       String,  :nullable => false
          column :config,     Yaml,    :nullable => false

          column :project_id, Integer
        end
      end
    end

    migration 2, :add_commits, :verbose => true do
      up do
        class ::Integrity::Build
          property :commit_identifier, String
          property :commit_metadata,   Yaml,   :lazy => false
          property :project_id,        Integer
        end

        create_table :integrity_commits do
          column :id,           Integer,  :serial => true
          column :identifier,   String,   :nullable => false
          column :message,      String,   :nullable => false, :length => 255
          column :author,       String,   :nullable => false, :length => 255
          column :committed_at, DateTime
          column :created_at,  DateTime
          column :updated_at,  DateTime

          column :project_id,   Integer
        end

        modify_table :integrity_builds do
          add_column :commit_id,    Integer
          add_column :started_at,   DateTime
          add_column :completed_at, DateTime
        end

        # Die, orphans, die
        Build.all(:project_id => nil).destroy!

        # sqlite hodgepockery
        all_builds = Build.all.each {|b| b.freeze }
        drop_table :integrity_builds
        create_table :integrity_builds do
          column :id,           Integer, :serial => true
          column :started_at,   DateTime
          column :completed_at, DateTime
          column :successful,   Boolean
          column :output,       Text,    :nullable => false, :default => ""
          column :created_at,   DateTime
          column :updated_at,   DateTime

          column :commit_id,    Integer
        end

        all_builds.each do |build|
          commit = Commit.first(:identifier => build.commit_identifier)

          if commit.nil?
            commit = Commit.create(:identifier   => build.commit_identifier,
                                   :message      => build.commit_metadata[:message],
                                   :author       => build.commit_metadata[:author],
                                   :committed_at => build.commit_metadata[:date],
                                   :project_id   => build.project_id)
          end

          Build.create(:commit_id    => commit.id,
                       :started_at   => build.created_at,
                       :completed_at => build.updated_at,
                       :successful   => build.successful,
                       :output       => build.output)
        end
      end
    end

    migration 3, :add_enabled_column do
      up do
        modify_table(:integrity_notifiers) { add_column :enabled, Boolean }
      end

      down do
        # TODO: sqlite doesn't support DROP COLUMN ...
        # modify_table(:integrity_notifiers) { drop_column :enabled }
      end
    end

    migration 4, :nil_commit_metadata do
      up do
        all_commits = Commit.all.collect { |c| c.dup }
        drop_table :integrity_commits

        create_table :integrity_commits do
          column :id,           Integer,  :serial => true
          column :identifier,   String,   :nullable => false
          column :message,      String,   :nullable => true, :length => 255
          column :author,       String,   :nullable => true, :length => 255
          column :committed_at, DateTime
          column :created_at,  DateTime
          column :updated_at,  DateTime

          column :project_id,   Integer
        end

        all_commits.each { |commit| Commit.create(commit.attributes) }
      end
    end


    migration 5, :add_scm_column do
      up do
        modify_table :integrity_projects do
          add_column :scm, String, :default => "git"
        end
      end
    end
  end
end

=begin
TODO: drop the :building column of the project table

    migration 5, :remove_building_column do
      up do
        modify_table(:integrity_projects) { drop_column :building }
      end
    end
=end
