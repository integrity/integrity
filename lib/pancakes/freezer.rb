module Pancakes
  module Freezer
    extend self
    extend HonestyCluster::AwsClients

    BUCKET = 'grnds-development-coreos'

    def stack_exists?(stack_id)
      !!s3_client(:development).head_object(bucket: BUCKET, key: stack_fname(stack_id))
    rescue Aws::S3::Errors::NotFound
      return false
    end

    def delete_stack(stack_id)
      s3_client(:development).delete_object(bucket: BUCKET, key: stack_fname(stack_id))
    end

    def stack_fname(stack_id)
      "freezer/#{Pancakes.config.freezer.namespace}/frozen_stack_#{stack_id}.sql.gz"
    end
  end
end
