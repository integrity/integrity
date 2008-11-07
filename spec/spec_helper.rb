require File.dirname(__FILE__) + "/../lib/integrity"
$:.unshift Integrity.root / "vendor/rspec/lib"
$:.unshift Integrity.root / "vendor/rspec_hpricot_matchers/lib"

require 'spec'
require 'spec/interop/test'
require 'sinatra'
require 'sinatra/test/unit'
require 'rspec_hpricot_matchers'
require 'haml'
require Integrity.root / 'spec/form_field_matchers'

Spec::Runner.configure do |config|
  config.include RspecHpricotMatchers
  config.include FormFieldHpricotMatchers
  
  config.before(:each) do
    DataMapper.setup(:default, "sqlite3::memory:")
    Integrity::Project.auto_migrate!
    Integrity::Build.auto_migrate!
    Integrity::Notifier.auto_migrate!
  end
end

module NotifierSpecHelper
  def mock_build(messages={})
    messages = {
      :project => stub("project", :name => "Integrity", :permalink => "integrity"),
      :commit_identifier => "e7e02bc669d07064cdbc7e7508a21a41e040e70d",
      :short_commit_identifier => "e7e02b",
      :status => :success,
      :successful? => true,
      :commit_message => "the commit message",
      :commit_author => stub("author", :name => "Nicolás Sanguinetti"),
      :commited_at => Time.mktime(2008, 07, 25, 18, 44),
      :output => "the output \e[31mwith color coding\e[0m"
    }.merge(messages)
    @build ||= stub("build", messages)
  end
  
  def notifier_config(overrides={})
    @config ||= overrides
  end
  
  def notifier
    @notifier ||= stub("notifier", :method_missing => nil)
  end
  
  def the_form(locals = {})
    locals = { :config => {} }.merge(locals)
    @form ||= Haml::Engine.new(klass.to_haml).render(self, locals)
  end
end

describe "A notifier", :shared => true do  
  it "should have a `notify_of_build' class method" do
    klass.should respond_to(:notify_of_build)
  end
  
  it "should have a `to_haml' class method" do
    klass.should respond_to(:to_haml)
  end
end
