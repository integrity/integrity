require File.dirname(__FILE__) + "/../helpers"

class SCMTest < Test::Unit::TestCase
  def scm(uri)
    SCM.new(Addressable::URI.parse(uri), "master", "foo")
  end

  it "recognizes git URIs" do
    scm("git://example.org/repo").should be_an(SCM::Git)
    scm("git@example.org/repo.git").should be_an(SCM::Git)
    scm("git://example.org/repo.git").should be_an(SCM::Git)
  end

  it "raises SCMUnknownError if it can't figure the SCM from the URI" do
    lambda { scm("scm://example.org") }.should raise_error(SCM::SCMUnknownError)
  end
  
  it "doesn't need the working tree path for all operations, so it's not required on the constructor" do
    lambda {
      SCM.new(Addressable::URI.parse("git://github.com/foca/integrity.git"), "master")
    }.should_not raise_error
  end
  
  describe "SCM::Git::URI" do
    uris = [
      "rsync://host.xz/path/to/repo.git/",
      "rsync://host.xz/path/to/repo.git",
      "rsync://host.xz/path/to/repo.gi",
      "http://host.xz/path/to/repo.git/",
      "https://host.xz/path/to/repo.git/",
      "git://host.xz/path/to/repo.git/",
      "git://host.xz/~user/path/to/repo.git/",
      "ssh://[user@]host.xz[:port]/path/to/repo.git/",
      "ssh://[user@]host.xz/path/to/repo.git/",
      "ssh://[user@]host.xz/~user/path/to/repo.git/",
      "ssh://[user@]host.xz/~/path/to/repo.git",
      "host.xz:/path/to/repo.git/",
      "host.xz:~user/path/to/repo.git/",
      "host.xz:path/to/repo.git",
      "user@host.xz:/path/to/repo.git/",
      "user@host.xz:~user/path/to/repo.git/",
      "user@host.xz:path/to/repo.git",
      "user@host.xz:path/to/repo",
      "user@host.xz:path/to/repo.a_git"
    ]

    uris.each do |uri|
      it "parses the uri #{uri}" do
        git_url = SCM::Git::URI.new(uri)
        git_url.working_tree_path.should == "path-to-repo"
      end
    end
  end
end

