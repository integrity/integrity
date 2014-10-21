source 'https://rubygems.org'

gem 'unicorn'
gem 'rack-contrib'

gem 'mysql2'
gem 'activerecord', '~> 3.2'
gem 'data_mapper', '~> 1.2'
gem 'dm-mysql-adapter'

# Workaround until https://github.com/datamapper/dm-core/issues/242
# is fixed in a released version of datamapper.
gem 'dm-core', git: 'git://github.com/datamapper/dm-core', branch: 'release-1.2'

gem 'haml'
gem 'sass'

gem 'chronic_duration'
gem 'sinatra'
gem 'sinatra-authorization'

gem 'bcat'
gem 'rake'
gem 'rconfig', '0.4.3.1', require: 'rconfig'
gem 'i18n'

gem 'capistrano', '2.15.4'
gem 'rvm-capistrano', '1.3.4'
gem 'capistrano-deploytags'

# Dependency for DelayedJob builder
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'daemons'

# These are dependencies for the various notifiers. Uncomment as appropriate.
gem 'pony'                                      # E-mail
# gem 'aws-ses', '~> 0.4.3', require: 'aws/ses' # SES E-mail
# gem 'broach', '0.2.1'                         # Campfire
# gem 'nap', '0.4'                              # HTTP
# gem 'bunny', '0.6.0'                          # AMQP

group :development do
  gem 'debugger'
  gem 'pry'
  gem 'pry-debugger'
  gem 'awesome_print'
end

group :test do
  gem 'aws-ses', '~> 0.4.3', require: 'aws/ses'
  gem 'extlib'
  gem 'rr'
  gem 'mocha'
  gem 'redgreen'
  gem 'dm-sweatshop', git: 'git://github.com/p/dm-sweatshop-without-parsetree', branch: 'integrity'
  gem 'randexp'
  gem 'rack-test'
  gem 'nokogiri'
  gem 'hpricot'
  gem 'contest'
  gem 'webrat'
  gem 'broach'
  gem 'nap'
  gem 'bunny'
  gem 'shout-bot'
  gem 'webmock'
  gem 'turn'
  gem 'timecop'
end
