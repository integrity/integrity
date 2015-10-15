module Integrity
  class DelayedBuilder
    def initialize(options)
      ActiveRecord::Base.default_timezone = :utc
      ActiveRecord::Base.establish_connection(options)

      Delayed::Worker.backend = :active_record

      ActiveRecord::Migration.suppress_messages do
        unless Delayed::Job.table_exists?
          ActiveRecord::Schema.define do
            create_table :delayed_jobs, force: true do |t|
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
          Integrity.logger
        end
      end
    end

    def enqueue(build)
      Delayed::Job.enqueue(BuildJob.new(build))
    end

    def run(action, build=nil)
      Delayed::Job.enqueue(BuildManagerJob.new(action, build))
    end

    def check_load!
      Delayed::Job.enqueue(LoadManagerJob.new)
    end

    class BuildJob
      def initialize(build)
        @build = build.is_a?(Build) ? build.id : build
      end

      def perform
        Build.get!(@build).run!
        #Integrity::Event.trigger('load:changed')
      end
    end

    class BuildManagerJob
      def initialize(action, build=nil)
        @build = build.is_a?(Build) ? build.id : build
        @action = action
      end

      def perform
        @action &&= @action.to_sym
        @build &&= Build.get!(@build)
        Integrity::Builder.send(@action, @build)
      end
    end

    class LoadManagerJob
      def perform
        Integrity.instance_manager.refresh
      end
    end
  end
end
