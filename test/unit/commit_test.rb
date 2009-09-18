require File.dirname(__FILE__) + "/../helpers"

class CommitTest < Test::Unit::TestCase
  test "fixture is valid and can be saved" do
    assert_change(Commit, :count) {
      commit = Commit.gen(:with_project)
      assert commit.valid? && commit.save
    }
  end

  before(:each) do
    @commit = Commit.gen(
      :message    => "Initial commit",
      :identifier => "658ba96cb0235e82ee720510c049883955200fa9",
      :author     => "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>")
  end

  it "has an identifier" do
    assert_equal "658ba96cb0235e82ee720510c049883955200fa9",
      @commit.identifier
  end

  it "has a short identifier" do
    assert_equal "658ba96", @commit.short_identifier

    @commit.identifier = "402"
    assert_equal "402", @commit.short_identifier
  end

  it "has an author" do
    assert_equal "Nicolás Sanguinetti", @commit.author.name
    assert_equal "contacto@nicolassanguinetti.info", @commit.author.email
    assert_equal "Nicolás Sanguinetti <contacto@nicolassanguinetti.info>",
      @commit.author.to_s

    assert_equal @commit.author.full, @commit.author.to_s
    assert_match /not loaded/, Commit.gen(:author => nil).author.to_s

    assert_equal "foo",     Commit.new(:author => "foo").author.name
    assert_equal "unknown", Commit.new(:author => "foo").author.email
  end

  it "has a message" do
    assert_equal "Initial commit", @commit.message
    assert_match /not loaded/, Commit.gen(:message => nil).message
  end

  it "has a committed date" do
    assert_kind_of DateTime,
      Commit.gen(:committed_at => Time.utc(2008, 10, 12, 14, 18, 20)).committed_at
  end

  it "has a human readable status" do
    assert_match /^Built (.*?) successfully$/,
      Commit.gen(:successful).human_readable_status

    assert_match /^Built (.*?) and failed$/,
      Commit.gen(:failed).human_readable_status

    assert_match(/^(.*?) hasn\'t been built yet$/,
      Commit.gen(:pending).human_readable_status)

    assert_match(/^(.*?) is building$/,
      Commit.gen(:building).human_readable_status)
  end

  it "has a status" do
    assert Commit.gen(:successful).successful?
    assert Commit.gen(:failed).failed?
    assert Commit.gen(:pending).pending?
    assert Commit.gen(:building).building?
  end
end
