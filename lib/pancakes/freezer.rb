module Pancakes
  module Freezer
    extend self

    BUCKET = 'grnds-development-coreos'

    def s3
      @s3 ||= Aws::S3::Client.new(
        credentials: Aws::Credentials.new(ENV['DEV_AWS_ACCESS_KEY_ID'], ENV['DEV_AWS_SECRET_ACCESS_KEY'])
      )
    end

    def stack_exists?(stack_id)
      !!s3.head_object(bucket: BUCKET, key: stack_fname(stack_id))
    rescue Aws::S3::Errors::NotFound
      return false
    end

    def delete_stack(stack_id)
      s3.delete_object(bucket: BUCKET, key: stack_fname(stack_id))
    end

    def stack_fname(stack_id)
      "freezer/#{Pancakes.config.freezer.namespace}/frozen_stack_#{stack_id}.sql.gz"
    end
  end
end
