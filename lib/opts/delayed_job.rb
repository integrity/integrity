require 'delayed_job'

Delayed::Worker.delay_jobs              = true
Delayed::Worker.destroy_failed_jobs     = false
Delayed::Worker.sleep_delay             = 60
Delayed::Worker.max_attempts            = 2
Delayed::Worker.max_run_time            = 15.minutes
Delayed::Worker.read_ahead              = 10
Delayed::Worker.default_queue_name      = 'integrity'
Delayed::Worker.logger                  = Integrity.logger
Delayed::Worker.raise_signal_exceptions = :term