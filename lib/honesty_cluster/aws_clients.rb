module HonestyCluster
  module AwsClients
    extend self

    CREDS = {
      development: {
        access_key_id:     'DEV_AWS_ACCESS_KEY_ID',
        secret_access_key: 'DEV_AWS_SECRET_ACCESS_KEY',
      },
      test: {
        access_key_id:     'AWS_ACCESS_KEY_ID',
        secret_access_key: 'AWS_SECRET_ACCESS_KEY',
      },
    }

    def s3_client(env)
      @__s3_clients ||= {}
      @__s3_clients[env] ||= Aws::S3::Client.new(
        credentials: Aws::Credentials.new(ENV[CREDS[env][:access_key_id]], ENV[CREDS[env][:secret_access_key]])
      )
    end
  end
end

