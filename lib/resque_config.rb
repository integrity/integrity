require 'resque'
require 'resque/log_formatters'
require 'resque/log_formatters/very_verbose_formatter'

# Resque.redis = {host: '127.0.0.1', port: 6379, db: 0}
Resque.redis = {host: '172.31.44.67', port: 6379, db: 0}
Resque.logger = Logger.new('/var/log/resque.log', 'weekly')
Resque.logger.level = Logger::DEBUG
Resque.logger.formatter = Resque::VeryVerboseFormatter.new