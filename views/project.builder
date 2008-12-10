xml.instruct!
xml.rss "version" => "2.0" do
 xml.channel do

   xml.title       @project.name
   xml.link        project_url(@project)
   xml.description @project.uri

   @project.builds.each do |build|
     xml.item do
       xml.title       "Build #{build.short_commit_identifier} #{build.successful? ? "succeeded" : "failed"}"
       xml.link        build_url(build)
       xml.description "Build #{build.commit_identifier} was committed by #{build.commit_author.name} on #{pretty_date build.commited_at}: <br />#{build.commit_message} <br />#{build.output}"
       xml.guid        build_url(build)
     end
   end
 end
end