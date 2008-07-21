require File.dirname(__FILE__) + '/spec_helper'

describe "Sinatra app to handle GitHub's post-receive hooks" do
  def payload
    <<-EOS
      { "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
        "repository": {
          "url": "http://github.com/defunkt/github",
          "name": "github",
          "owner": {
            "email": "chris@ozmm.org",
            "name": "defunkt" 
          }
        },
        "commits": {
          "41a212ee83ca127e3c8cf465891ab7216a705f59": {
            "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
            "author": {
              "email": "chris@ozmm.org",
              "name": "Chris Wanstrath" 
            },
            "message": "okay i give in",
            "timestamp": "2008-02-15T14:57:17-08:00" 
          },
          "de8251ff97ee194a289832576287d6f8ad74e3d0": {
            "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
            "author": {
              "email": "chris@ozmm.org",
              "name": "Chris Wanstrath" 
            },
            "message": "update pricing a tad",
            "timestamp": "2008-02-15T14:36:34-08:00" 
          }
        },
        "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
        "ref": "refs/heads/master" }
    EOS
  end

  before(:each) do
    require Integrity.root / "lib" / "integrity" / "github"
    Integrity.stub!(:new)
    @project = mock('project', :build => true)
    Integrity::Project.stub!(:first).and_return(@project)
  end

  it 'should be successful' do
    post_it '/github', :payload => payload
    status.should == 200
  end

  it 'should return a confirmation message' do
    post_it '/github', :payload => payload
    body.should == 'Thanks, build started.'
  end

  it 'should be 422 without payload' do
    post_it '/github'
    status.should == 422
  end

  it 'should find the Project by its name' do
    Integrity::Project.should_receive(:first).with(:permalink => 'github').and_return(@project)
    post_it '/github', :payload => payload
  end

  it 'should be 404 if unknown project' do
    Integrity::Project.stub!(:first).and_return(nil)
    post_it '/github', :payload => payload
    status.should == 404
    body.should == "Unknown project `github'"
  end

  it 'should make a new build for each commit' do
    @project.should_receive(:build).with('41a212ee83ca127e3c8cf465891ab7216a705f59')
    @project.should_receive(:build).with('de8251ff97ee194a289832576287d6f8ad74e3d0')
    post_it '/github', :payload => payload
  end
  
  describe 'With invalid payload' do
    before(:each) do
      JSON.stub!(:parse).and_raise(JSON::ParserError.new('error message'))
    end

    it 'should rescue any JSON parse error and return a 422 status code' do
      post_it '/github'
      @response.status.should == 422
    end

    it 'should rescue any JSON parse error and return the error' do
      post_it '/github'
      @response.body.should == 'error message'
    end

    it 'should return error in plain/text' do
      post_it '/github'
      @response['Content-Type'].should == 'text/plain'
    end
  end
end
