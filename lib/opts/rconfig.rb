# Use this hook to configure rconfig mailer, warden hooks and so forth. The first
# four configuration values can also be set straight in your models.
RConfig.setup do |config|

  # ==> Configuration File Load Paths
  # The list of directories from which to load configuration files.
  # If This is a Rails Application, it will default to "#{Rail.root}/config",
  # It will also check for the existence of a CONFIG_ROOT constant, and adds
  # it, if found. I will also attempt to use "config" if such a directory 
  # exists in the application root. Otherwise it will be empty, in which case 
  # one or more paths must be added manually here.
  #
  config.load_paths = ['config']

  # ==> Overlay Suffix
  # Use this to add a custom cascade to be used beyond that of environment,
  # or platform cascades. For instance, besides supporting configuration for
  # development as 'application_development.yml', you can use cascade to also 
  # provide a locale, by setting config.cascade = 'GB', RConfig will look for 
  # the file 'application_development_GB.yml'
  # See documentation for details on how cascading configurations work.
  #
  # config.cascade = false

  # ==> Configuration File Types
  # The type of configuration files to load within the configuration
  # directories. The supported file types are yaml, xml, and property
  # files (.property). One or more can be used at once.
  # The default is to use yml files only, but other types can added
  # by using the pre-defined constants or simply setting an new array.
  #
  # Pre-defined Constants
  #   YML_FILE_TYPES = [:yml, :yaml]                        # yml, yaml => yaml files, parsable by YAML library
  #   XML_FILE_TYPES = [:xml]                               # xml => self-explanatory
  #   CNF_FILE_TYPES = [:cnf, :conf, :config, :properties]  # conf, properties => key=value based config files
  #   CONFIG_FILE_TYPES = YML + XML + CNF                   # All => All of the above file types combined
  #
  # Examples:
  #   config.file_types = CONFIG_FILE_TYPES
  #   config.file_types = [ :yml, :xml, :property ]
  #
  config.file_types = [ :yml ]

  # ==> Enable/Disable Cache Reload 
  # Flag variable indicating whether or not periodic reloads should 
  # be performed. Defaults to false.
  #
  # config.enable_reload = false

  # ==> Interval for Reloading Configuration Data
  # The interval in which to perform periodic reloading of config files (in
  # seconds). Files are checked befor reload is executed. They are not reloaded 
  # if the data has not changed. Defaults to 300 seconds (5 minutes).
  #
  # config.reload_interval = 300

  # ==> Logger
  # The logger rconfig will log to. By default RConfig uses the Rails logger,
  # or the standard Ruby logger if this is not a rails environment. The 
  # The logger can be changed to a different logger, like Log4r.  You can also stick with the RConfig logger, but customize
  # it's log options The available options are as follows:
  # * level:  The log level to log at. Default: ERROR
  # * output: The outputter to send messages to. Default: STDERR
  # * file:   The name of the file to log to (cannot be used with output).
  # * date_format: The format of the timestamp when something is logged. 
  # Options are passed in a hash to the new method.
  # Example: 
  #   RConfig::Logger.new(
  #     :file        => "#{Rails.root}/log/production.log",
  #     :date_format => "%Y-%m-%d %H:%M:%S",
  #     :level       => RConfig::Logger::ERROR
  #   )
  #
  config.logger = false

  # ==> Log Level
  # The log level the specified logger will be set to. By default it is set to WARN.
  # It can also be set when initializing the logger, specifying the level in the options.
  #
  config.log_level = RConfig::Logger::WARN
end

