require "helper"

class BootstrapperTest < IntegrityTest
  def create_project
    Integrity.bootstrap do |b|
      b.project "Integrity" do |p|
        p.uri     = "git://github.com/integrity/integrity"
        p.command = "gem bundle && ./bin/rake"
        p.public
      end
    end
  end

  it "creates a project" do
    create_project

    assert_equal 1, Project.count

    project = Project.first
    assert project.public?

    assert_equal "Integrity",                            project.name
    assert_equal "git://github.com/integrity/integrity", project.uri.to_s
    assert_equal "master",                               project.branch
    assert_equal "gem bundle && ./bin/rake",             project.command
  end

  it "updates the project if it already exists" do
    create_project

    Integrity.bootstrap do |b|
      b.project "Integrity" do |p|
        p.uri     = "git://github.com/integrity/integrity"
        p.branch  = "sinatra10"
        p.command = "make"
        p.private
      end
    end

    assert_equal 1, Project.count
    assert_equal "make", Project.first.command
    assert ! Project.first.public?
  end

  it "raises if stuff are missing" do
    assert_raise(RuntimeError) {
      Integrity.bootstrap do |b|
        b.project("Foobar") { |p| p.branch = "foobar" }
      end
    }
  end
end
