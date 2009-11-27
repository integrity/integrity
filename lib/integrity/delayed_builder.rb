require "delayed_job"

module Integrity
  module DelayedBuilder
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

    def self.build(build)
      Delayed::Job.enqueue(BuildJob.new(build))
    end

    class BuildJob
      def initialize(build)
        @build = build.id
      end

      def perform
        Builder.new(Build.get(@build)).build
      end
    end
  end
end
