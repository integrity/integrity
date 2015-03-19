module Integrity
  module Pancakes
    class Freezer
      extend self

      FREEZER_S3_URL = 's3://grnds-development-coreos/freezer'

      def remove(stack)
        stack.log "removing frozen data"
        system "aws s3 rm --recursive #{FREEZER_S3_URL}/#{stack.branch_identifier}/"
      end
    end
  end
end
