require 'logging'
require 'delayed_job'

if Integrity.environment == :production
  logger = Logging.logger['delayed_job']
  logger.add_appenders Logging.appenders.syslog('delayed_job')
  logger.level = :debug
else
  logger = Integrity.logger
end

Delayed::Worker.delay_jobs              = true
Delayed::Worker.destroy_failed_jobs     = false
Delayed::Worker.sleep_delay             = 1
Delayed::Worker.max_attempts            = 2
Delayed::Worker.max_run_time            = 30.minutes
Delayed::Worker.read_ahead              = 5
Delayed::Worker.default_queue_name      = 'integrity'
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger                  = logger


