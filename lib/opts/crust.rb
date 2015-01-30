ssh_key_file = ENV['SSH_KEY_FILE'].presence || "#{ENV['HOME']}/.ssh/id_rsa"

Crust.configure do |config|
  config.host   = 'coreos.test.grandrounds.com'
  config.logger = Integrity.logger
  config.ssh    = {keys: ssh_key_file, paranoid: false}
  config.service_templates = "#{Integrity.root}/services/templates"
end
