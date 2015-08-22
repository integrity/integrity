module Pancakes
  module Freezer
    extend self

    DEV_BUCKET = 'grnds-development-coreos'

    def s3_development
      @__s3_development ||= Aws::S3::Client.new(
        credentials: Aws::Credentials.new(ENV['DEV_AWS_ACCESS_KEY_ID'], ENV['DEV_AWS_SECRET_ACCESS_KEY'])
      )
    end

    def stack_exists?(stack_id)
      !!s3_development.head_object(bucket: DEV_BUCKET, key: stack_fname(stack_id))
    rescue Aws::S3::Errors::NotFound
      return false
    end

    def delete_stack(stack_id)
      s3_development.delete_object(bucket: DEV_BUCKET, key: stack_fname(stack_id))
    end

    def stack_fname(stack_id)
      "freezer/#{Pancakes.config.freezer.namespace}/frozen_stack_#{stack_id}.sql.gz"
    end
  end
end
