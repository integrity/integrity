require "init"
require "resque/server"

map "/resque" do
  run Resque::Server
end

map "/" do
  run Integrity.app
end
