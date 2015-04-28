module Pancakes
  module Freezer
    extend self

    FREEZER_S3_URL = 's3://grnds-development-coreos/freezer'

    def remove(branch_identifier)
      # TODO
      #system "aws s3 rm --recursive #{FREEZER_S3_URL}/#{branch_identifier}"
    end
  end
end
