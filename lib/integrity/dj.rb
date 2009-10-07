require "delayed_job"

module Integrity
  class DelayedBuilder
    def self.setup(options)
      ActiveRecord::Base.establish_connection(options)
      ActiveRecord::Schema.define {
        create_table :delayed_jobs, :force => true do |table|
          table.integer  :priority, :default => 0
          table.integer  :attempts, :default => 0
          table.text     :handler
          table.text     :last_error
          table.datetime :run_at
          table.datetime :locked_at
          table.datetime :failed_at
          table.string   :locked_by
          table.timestamps
        end
      } unless Delayed::Job.table_exists?

      # TODO
      Delayed::Job.class_eval {
        def logger
          @_logger ||= Integrity.config.logger
        end
      }
    end

    def initialize(buildable)
      build = Project.for(buildable).builds.create(:commit => Commit.new)
      @buildable = buildable.update("build" => build.id)
    end

    def build
      Delayed::Job.enqueue(self)
    end

    def perform
      ProjectBuilder.new(@buildable).build
    end
  end
end
