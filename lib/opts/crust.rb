ssh_key_file = ENV['SSH_KEY_FILE'].presence || "#{ENV['HOME']}/.ssh/id_rsa"

Crust.configure do |config|
  config.logger = Integrity.logger,
  config.service_templates = "#{Integrity.root}/services/templates",
  config.fleetctl_options = {
    fleet_host: 'coreos.etcd.1.test.grandrounds.com',
    ssh_options: {
      keys: ssh_key_file,
      paranoid: false
    },
    executable: 'fleetctl --debug'
    }
end
