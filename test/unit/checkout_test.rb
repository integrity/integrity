require "helper"

class CheckoutTest < IntegrityTest
  test "checkout_proc" do
    args = {}

    Integrity.configure do |c|
      c.checkout_proc = Proc.new do |runner, repo_uri, branch, sha1, target_directory|
        args[:repo_uri] = repo_uri
        args[:branch] = branch
        args[:sha1] = sha1
        args[:target_directory] = target_directory
      end
    end

    checkout = Checkout.new(Project.gen(:integrity), 'a-sha1', 'a-directory', nil)

    assert args.empty?
    checkout.run
    assert !args.empty?

    # from fixture
    assert_equal 'git://github.com/foca/integrity.git', args[:repo_uri].to_s
    assert_equal 'master', args[:branch]
    # from parameters
    assert_equal 'a-sha1', args[:sha1]
    assert_equal 'a-directory', args[:target_directory]
  end
end
