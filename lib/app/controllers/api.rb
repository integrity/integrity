module Integrity
  module Api
    def self.included(base)
      base.class_eval do

        post '/status.json', provides: :json do
          params.symbolize_keys!
          @format = :json
          log("[Build:#{params[:build_id]}][fi] POST /status.json - completing current project with params #{params.slice(:success, :sha, :build_id)} Project is #{current_project.inspect}")
          current_project.build_complete!(params.slice(:success, :sha, :build_id))
          json current_project
        end

        post '/hook.json', provides: :json do
          @format = :json

          pre_msg = "[HOOK] hook.json ::"

          log "#{pre_msg} payload received. params: #{params.inspect}"

          payload = Payload.new(params)
          halt 404 unless payload.project

          if payload.deleted?
            log "#{pre_msg} Received branch delete notice for: #{payload.branch_name}"
            if branch = payload.branch
              log "#{pre_msg} Found matching branch. DELETING BRANCH: [#{branch.id}] (#{branch.inspect})"
              branch.destroy
              json branch and return
            end
          end


          if not payload.project
            log "#{pre_msg} no project in payload"
            halt 404
          elsif not payload.commit
            log "#{pre_msg} no commit in payload"
            halt 404
          end

          build = payload.build!

          log "#{pre_msg} Build: #{build.inspect}"

          if diligence = Integrity::DiligenceBranch.first(branch: build.branch)
            diligence.rebuild_environment
          end

          json build
        end

        get '/utilization.json' do
          json Integrity.instance_manager.utilization_metrics
        end

        get '/coreos/key' do
          halt Integrity.private_key
        end

        def self.load_translations
          I18n.load_path += Dir[File.join(settings.root, 'config', 'locale', '*.yml')]
          I18n.backend.load_translations
        end

      end
    end
  end
end