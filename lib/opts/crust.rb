Crust.configure do |config|
  config.host   = 'coreos.test.grandrounds.com'
  config.logger = Integrity.logger
  config.ssh    = {keys: '/home/ozzie/.ssh/id_rsa'}
  config.service_template = "#{Integrity.root}/services/templates/service.erb"
end
