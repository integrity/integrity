require "diddies"

module Integrity
  module Helpers
    include Rack::Utils
    include Sinatra::Authorization
    alias_method :h, :escape_html

    def authorization_realm
      "Integrity"
    end

    def authorized?
      return true unless Integrity.config[:use_basic_auth]
      !!request.env["REMOTE_USER"]
    end

    def authorize(user, password)
      if Integrity.config[:hash_admin_password]
        password = Digest::SHA1.hexdigest(password)
      end

      !Integrity.config[:use_basic_auth] ||
      (Integrity.config[:admin_username] == user &&
        Integrity.config[:admin_password] == password)
    end

    def unauthorized!(realm=authorization_realm)
      header "WWW-Authenticate" => %(Basic realm="#{realm}")
      throw :halt, [401, show(:unauthorized, :title => "incorrect credentials")]
    end

    def invalid_payload!(msg=nil)
      throw :halt, [422, msg || "No payload given"]
    end

    def current_project
      @project ||= Project.first(:permalink => params[:project]) or raise Sinatra::NotFound
    end

    def current_build
      @build ||= current_project.builds.first(:commit_identifier => params[:build]) or raise Sinatra::NotFound
    end

    def show(view, options={})
      @title = breadcrumbs(*options[:title])
      haml view
    end

    def pages
      @pages ||= [["projects", "/"], ["new project", "/new"]]
    end

    def breadcrumbs(*crumbs)
      crumbs[0..-2].map do |crumb|
        if page_data = pages.detect {|c| c.first == crumb }
          %Q(<a href="#{page_data.last}">#{page_data.first}</a>)
        elsif @project && @project.permalink == crumb
          %Q(<a href="#{project_url(@project)}">#{@project.permalink}</a>)
        end
      end + [crumbs.last]
    end

    def cycle(*values)
      @cycles ||= {}
      @cycles[values] ||= -1 # first value returned is 0
      next_value = @cycles[values] = (@cycles[values] + 1) % values.size
      values[next_value]
    end

    def integrity_domain
      Addressable::URI.parse(Integrity.config[:base_uri]).to_s
    end

    def project_path(project, *path)
      "/" << [project.permalink, *path].join("/")
    end

    def project_url(project, *path)
      "#{integrity_domain}#{project_path(project, *path)}"
    end

    def push_url_for(project)
      "#{project_url(project)}/push"
    end

    def build_path(build)
      "/#{build.project.permalink}/builds/#{build.commit_identifier}"
    end

    def build_url(build)
      "#{integrity_domain}#{build_path(build)}"
    end

    def errors_on(object, field)
      return "" unless errors = object.errors.on(field)
      errors.map {|e| e.gsub(/#{field} /i, "") }.join(", ")
    end

    def error_class(object, field)
      object.errors.on(field).nil? ? "" : "with_errors"
    end

    def checkbox(name, condition, extras={})
      attrs = { :name => name, :type => "checkbox", :value => "1" }
      attrs.merge(condition ? { :checked => "checked" } : {})
      attrs.merge(extras)
    end

    def bash_color_codes(string)
      string.gsub("\e[0m", '</span>').
        gsub("\e[31m", '<span class="color31">').
        gsub("\e[32m", '<span class="color32">').
        gsub("\e[33m", '<span class="color33">').
        gsub("\e[34m", '<span class="color34">').
        gsub("\e[35m", '<span class="color35">').
        gsub("\e[36m", '<span class="color36">').
        gsub("\e[37m", '<span class="color37">')
    end

    def pretty_date(date_time)
      today = Date.today
      if date_time.day == today.day && date_time.month == today.month && date_time.year == today.year
        "today"
      elsif date_time.day == today.day - 1 && date_time.month == today.month && date_time.year == today.year
        "yesterday"
      else
        date_time.strftime("on %b %d%o")
      end
    end

    def partial(template, locals={})
      haml("_#{template}".to_sym, :locals => locals, :layout => false)
    end

    def notifier_form(notifier)
      haml(notifier.to_haml, :layout => :notifier, :locals => {
        :config => current_project.config_for(notifier),
        :notifier => "#{notifier.to_s.split(/::/).last}",
        :enabled => current_project.notifies?(notifier)
      })
    end
  end
end
