module Pancakes
  module Freezer
    extend self

    BUCKET = 'grnds-development-coreos'

    def s3
      @s3 ||= Aws::S3::Client.new(
        credentials: Aws::Credentials.new(ENV['DEV_AWS_ACCESS_KEY_ID'], ENV['DEV_AWS_SECRET_ACCESS_KEY'])
      )
    end

    def stack_exists?(stack)
      !!s3.head_object(key: freezer_key(stack.id), bucket: BUCKET)
    rescue Aws::S3::Errors::NotFound
      return false
    end

    def freezer_key(stack_id)
      "freezer/frozen_stack_#{stack_id}.sql.gz"
    end

    def remove(branch_identifier)
      # TODO
      #system "aws s3 rm --recursive #{FREEZER_S3_URL}/#{branch_identifier}"
    end
  end
end
