require 'logging'
require 'delayed_job'

#class PollNotifier < Delayed::Plugin
  #callbacks do |lifecycle|
    #lifecycle.before(:loop) do |worker|
      #worker.say 'Checking for pending jobs'
    #end
  #end
#end

#Delayed::Worker.plugins << PollNotifier

Delayed::Worker.delay_jobs              = true
Delayed::Worker.destroy_failed_jobs     = false
Delayed::Worker.sleep_delay             = 1
Delayed::Worker.max_attempts            = 2
Delayed::Worker.max_run_time            = 10.minutes
Delayed::Worker.read_ahead              = 2
Delayed::Worker.default_queue_name      = 'integrity'
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger                  = Integrity.logger
