module Integrity
  module Builds
    def self.included(base)
      base.class_eval do

        # List Running Builds (Index)
        get '/running' do
          @builds = Integrity::Build.running
          show :running, title: 'running builds'
        end

        # Create Build From Commit (Re-build)
        post '/:project/builds/:build' do
          log("[Build:#{current_build.id}] /:project/builds/:build (Build:Re-build) build:#{current_build.inspect}, commit: #{current_build.commit.inspect}")
          @build = current_project.build(current_build.commit, true, params["template"])
          redirect build_url(@build)
        end

        # Show Build (Read)
        get '/:project/builds/:build' do
          @status = current_build.status
          show :build, title: ['projects', current_project.permalink, current_build.sha1_short]
        end

        # Delete Build
        delete '/:project/builds/:build' do
          log("[Build:#{current_build.id}] DELETE /:project/builds/:build (Delete build) build:#{current_build.inspect}")
          current_build.destroy!
          redirect root_url
        end

        # Cancel the Pending or Running Build
        post '/:project/builds/:build/fail_reason' do
          log("[Build:#{current_build.id}] fail_reason /:project/builds/:build/fail_reason (Give reason for failure) params:#{params}")
          current_build.update(fail_category: params["fail_reason"])
          redirect build_url(current_build)
        end

        # Cancel the Pending or Running Build
        post '/:project/builds/:build/cancel' do
          current_build.cancel_with_reason("user #{current_user.name}", 'manual kill', 'POST /:project/builds/:build/cancel')
          redirect build_url(current_build)
        end

        # Get Raw Build Output
        get '/:project/builds/:build/raw' do
          content_type :text
          current_build.output
        end

        # Send Build notification
        get '/:project/builds/:build/notify' do
          current_build.notify
          redirect build_url(current_build)
        end

        # Get Build Artifact
        get '/:project/builds/:build/artifacts/:artifact' do |project, build, artifact|
          artifact = CGI.unescape(artifact)
          artifact_files = current_build.artifact_files
          file = artifact_files.detect do |file|
            file[:relative_path] == artifact
          end

          if file.nil?
            halt 404
          end

          fs_path = current_build.build_directory.join(file[:relative_path])
          unless File.exist?(fs_path)
            halt 404
          end

          send_file fs_path, filename: file[:name]
        end

      end
    end
  end
end