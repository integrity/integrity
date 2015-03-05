module Integrity
  module Projects
    def self.included(base)
      base.class_eval do

        ['/?', '/projects', "/projects\.json", '/diligence_branches'].each do |path|
          before path do
            load_projects
          end
        end

        # List Projects (Index)
        ['/?', '/projects'].each do |path|
          get path, provides: 'html' do
            @masters = Integrity::Branch.all(name: 'master')
            @builds  = Integrity::Build.all(limit: 30, order: :created_at.desc)
            @pending = @builds.pending.all(order: :created_at.desc)
            @running = @builds.running.all(order: :started_at.desc)
            @completed = @builds.completed.all(order: :completed_at.desc)
            show :home, title: 'project'
          end
        end

        # List Projects (Index) (JSON)
        ['/?', "/projects\.json"].each do |path|
          get path, provides: 'json' do
            @format = :json
            projects_json = @projects.map do |project|
              project.attributes_for_json
            end
            wrapped_projects = {projects: projects_json}
            json wrapped_projects
          end
        end

        # Get Project (Show)
        get '/:project' do
          load_builds(current_project)
          load_branches
          @status = current_project.status
          @branches = current_project.branches(:name.not => 'master', order: [:name.asc, :created_at.desc]).first(7)
          @branches += current_project.branches(name: 'master')
          show :project, title: ['projects', current_project.name]
        end

        # Get Project (Show) (List ALL Builds)
        get '/:project/all' do
          load_builds(current_project, :all)
          load_branches(:all)
          show :project, title: ['projects', current_project.name]
        end

        # Get Project (Show) (JSON)
        get "/:project\.json" do
          @format = :json
          json current_project
        end

        # New Project (Form)
        get '/new' do
          @project = Project.new
          show :new, title: ['projects', 'new project']
        end

        # Create Project (Create)
        post '/?' do
          log("/? (Create Project) params:#{params.inspect}")
          @project = Project.new(params[:project_data])

          if @project.save
            update_notifiers_of(@project)
            redirect project_url(@project)
          else
            show :new, title: ['projects', 'new project']
          end
        end

        # Edit Project (Edit/Form)
        get '/:project/edit' do
          show :edit, title: ['projects', current_project.permalink, 'edit']
        end

        # Update Project (Update)
        put '/:project' do
          if current_project.update(params[:project_data])
            update_notifiers_of(current_project)
            redirect project_url(current_project)
          else
            show :new, title: ['projects', current_project.permalink, 'edit']
          end
        end

        # Delete Project (Delete)
        delete '/:project' do
          current_project.destroy
          redirect root_url
        end

        # Ping Project (Check if Project Exists)
        get '/:project/ping' do
          if current_project.status != :success
            halt 412, current_project.status.to_s
          else
            current_project.last_build.sha1
          end
        end

        # Get Project Status Icon
        get "/:project\.png" do
          send_file File.join(File.dirname(__FILE__), 'public', 'status', current_project.status.to_s + '.png')
        end

      end
    end
  end
end