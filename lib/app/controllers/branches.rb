module Integrity
  module Branches
    def self.included(base)
      base.class_eval do

        get '/:project/:branch' do
          load_builds(current_branch)
          show :branch, title: ['branches', current_branch.name]
        end

        # Get Project (List ALL Builds)
        get '/:project/:branch/all' do
          load_builds(@branch, :all)
          show :branch, title: ['branches', current_branch.name]
        end

      end
    end
  end
end