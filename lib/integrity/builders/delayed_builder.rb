require 'delayed_job'
require 'active_record'

module Integrity
  class DelayedBuilder
    def initialize(options)
      ActiveRecord::Base.default_timezone = :utc
      ActiveRecord::Base.establish_connection(options)

      Delayed::Worker.backend = :active_record

      ActiveRecord::Migration.suppress_messages do
        unless Delayed::Job.table_exists?
          ActiveRecord::Schema.define do
            create_t :delayed_jobs, force: true do |t|
              t.string   :queue
              t.integer  :priority, default: 0
              t.integer  :attempts, default: 0
              t.text     :handler
              t.text     :last_error
              t.datetime :run_at
              t.datetime :locked_at
              t.datetime :failed_at
              t.string   :locked_by
              t.timestamps
            end
          end
        end
      end

      Delayed::Job.class_eval do
        def logger
          @_logger ||= Integrity.logger
        end
      end
    end

    def enqueue(build)
      Delayed::Job.enqueue(BuildJob.new(build))
    end

    class BuildJob
      def initialize(build)
        @build = build.id
      end

      def perform
        Build.get!(@build).run!
      end
    end
  end
end
