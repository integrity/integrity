desc "Create the Integrity database"
task "db:migrate" do
  require File.dirname(__FILE__) + "/integrity-config"

  DataMapper.auto_migrate!
end
