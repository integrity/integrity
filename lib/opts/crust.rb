Crust.configure do |config|
  config.host   = 'coreos.test.grandrounds.com'
  config.logger = Integrity.logger
  config.ssh    = {keys: '/home/ubuntu/.ssh/id_rsa'}
  config.project_template_directory = "#{Integrity.root}/projects"
end