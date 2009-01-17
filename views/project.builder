xml.instruct!
xml.feed :xmlns => "http://www.w3.org/2005/Atom" do
  xml.title     "Build history for #{@project.name}"
  xml.subtitle  @project.uri
  xml.updated   @project.builds.first.created_at
  xml.link      :href => "#{project_url(@project)}.atom", :rel => "self"
  xml.id        "#{project_url(@project)}.atom"

  @project.builds.each do |build|
    xml.entry do
      xml.id        build_url(build)
      xml.link      :href => build_url(build), :rel => "alternate", :type => "text/html"
      xml.updated   build.created_at
      xml.published build.created_at

      xml.title "Built #{build.short_commit_identifier} #{build.successful? ? "successfully" : "and failed"}"
      xml.author { xml.name(build.commit_author.name) }
      xml.content("<div>#{partial(:build_info, :build => build)}</div>", :type => "html")
   end
  end
end
