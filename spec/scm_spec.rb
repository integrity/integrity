require File.dirname(__FILE__) + '/spec_helper'

module Integrity
  describe SCM do
    describe 'when loading an SCM adapter' do
      before :each do
        @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
      end

      it 'should instantiate the adapter with the given options' do
        Integrity::SCM::Git.should_receive(:new).with(@uri, 'master', "working/dir")
        Integrity::SCM.new(@uri, 'master', "working/dir")
      end

      it "should raise an error if the handler can't be found" do
        lambda do
          Integrity::SCM.new("foo/bar")
        end.should raise_error(SCM::SCMUnknownError, "could not find any SCM based on string 'foo/bar'")
      end
    end
    
    describe "loading Git repos" do
      it "should understand .git repos" do
        adapter = Integrity::SCM.new("git://selfhostedrepo.com/blah.git", "master", "working/dir")
        adapter.should be_a_kind_of(Integrity::SCM::Git)
      end

      it "should understand .git/ repos (ending with a slash)" do
        adapter = Integrity::SCM.new("git://selfhostedrepo.com/blah.git/", "master", "working/dir")
        adapter.should be_a_kind_of(Integrity::SCM::Git)
      end
    end
    
    describe "getting the working tree path from a uri" do
      it "should delegate to the actual adapter" do
        Integrity::SCM::Git.should_receive(:working_tree_path).with("git://foo/bar.git")
        SCM.working_tree_path("git://foo/bar.git")
      end
    end
  end
end
