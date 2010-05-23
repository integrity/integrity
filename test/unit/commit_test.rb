# encoding: UTF-8
require "helper"

class CommitTest < IntegrityTest
  test "fixture is valid and can be saved" do
    assert_change(Commit, :count) {
      commit = Commit.gen
      assert commit.valid? && commit.save
    }
  end

  setup do
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

    assert_equal "foo",     Commit.new(:author => "foo").author.name
    assert_equal "unknown", Commit.new(:author => "foo").author.email
  end

  it "has a message" do
    assert_equal "Initial commit", @commit.message
  end

  it "has a committed date" do
    assert_kind_of DateTime,
      Commit.gen(:committed_at => Time.utc(2008, 10, 12, 14, 18, 20)).committed_at
    assert_kind_of DateTime, Commit.gen(:committed_at => nil).committed_at
  end

  test "blank commit" do
    commit = Commit.new
    assert commit.valid? && commit.save

    assert commit.identifier.empty?
    assert commit.short_identifier.empty?
    assert_match /not loaded/, commit.author.to_s
    assert_match /not loaded/, commit.message
    assert_kind_of DateTime, commit.committed_at
  end
end
