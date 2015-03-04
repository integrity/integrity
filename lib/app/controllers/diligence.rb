module Integrity
  module Diligence
    def self.included(base)
      base.class_eval do

        before '/diligence_branches' do
          load_projects
        end

        get '/diligence_branches' do
          @active_diligence_branches = Integrity::DiligenceBranch.all(order: :id.desc, active: true)
          @inactive_diligence_branches = Integrity::DiligenceBranch.all(order: :id.desc, active: false)
          @branches = Integrity::Branch.all(limit:30, order: :last_build_id.desc)
          show :diligence_branches
        end

        get '/diligence_branches/:branch_id/start' do |branch_id|
          diligence_branch = Integrity::DiligenceBranch.first(:branch_id => branch_id)

          unless diligence_branch
            branch = Integrity::Branch.get(branch_id)
            diligence_branch = Integrity::DiligenceBranch.create(branch: branch)
          end

          diligence_branch.start
          redirect back
        end

        get '/diligence_branches/:id/stop' do |id|
          diligence_branch = Integrity::DiligenceBranch.get(id)
          diligence_branch.stop
          redirect back
        end

        get '/diligence_branches/:id/flip_lock' do |id|
          diligence_branch = Integrity::DiligenceBranch.get(id)
          diligence_branch.flip_lock
          redirect back
        end

      end
    end
  end
end