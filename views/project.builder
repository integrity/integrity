xml.instruct!
xml.feed :xmlns => "http://www.w3.org/2005/Atom" do
  xml.title     "Build history for #{@project.name}"
  xml.subtitle  @project.uri
  xml.updated   @project.last_commit.updated_at
  xml.link      :href => "#{project_url(@project)}.atom", :rel => "self"
  xml.id        "#{project_url(@project)}.atom"

  @project.commits.each do |commit|
    xml.entry do
      xml.id        commit_url(commit)
      xml.link      :href => commit_url(commit), :rel => "alternate", :type => "text/html"
      xml.updated   commit.created_at
      xml.published commit.created_at

      xml.title commit.human_readable_status
      xml.author { xml.name(commit.author.name) }
      xml.content("<div>#{partial(:commit_info, :commit => commit)}</div>", :type => "html")
   end
  end
end
