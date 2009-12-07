require "helper"

class RepositoryTest < Test::Unit::TestCase
  def path(uri, branch="master", commit="commit")
    Repository.new(uri, branch, commit).directory.
      relative_path_from(Integrity.directory).to_s
  end

  test "uri to path conversion" do
    assert_equal "git-github-com-integrity-bob-master/commit",
      path("git://github.com/integrity/bob")
    assert_equal "git-example-org-foo-repo-master/commit",
      path("git@example.org:~foo/repo")
    assert_equal "tmp-repo-git-master/commit", path("/tmp/repo.git")
    assert_equal "tmp-repo-git-foo/commit",    path("/tmp/repo.git", "foo")
  end
end
