require File.dirname(__FILE__) + '/../lib/integrity'
require File.dirname(__FILE__) + '/spec_fixture'
require 'spec'

module LoggingSpecHelper
  def self.included(mod)
    mod.before(:each) { Integrity.stub!(:log) }
  end
end

module NotifierSpecHelper
  def self.included(mod)
    mod.before(:each) { Integrity.stub!(:config).and_return(:base_uri => "http://localhost:4567") }
  end
  
  class Integrity::Notifier::Stub < Integrity::Notifier::Base
    def self.to_haml
      ""
    end
    
    def deliver!
      nil
    end
  end

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
    require 'haml'
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

module DatabaseSpecHelper
  def self.included(mod)
    mod.before(:each) { setup_database! }
  end

  def setup_database!
    DataMapper.setup(:default, 'sqlite3::memory:')
    DataMapper.auto_migrate!
  end
end

module AppSpecHelper
  def self.included(mod)
    require 'rspec_hpricot_matchers'
    require Integrity.root / 'spec/form_field_matchers'

    mod.send(:include, DatabaseSpecHelper)
    mod.send(:include, RspecHpricotMatchers)
    mod.send(:include, FormFieldHpricotMatchers)
  end

  def mock_project(messages={})
    messages = {
      :name => "Integrity",
      :permalink => "integrity",
      :new_record? => false,
      :uri => "git://github.com/foca/integrity.git",
      :branch => "master",
      :command => "rake",
      :public? => true,
      :builds => [],
      :config_for => {},
      :build => nil,
      :update_attributes => true,
      :save => true,
      :destroy => nil,
      :errors => stub("errors", :on => nil),
      :notifies? => false,
      :enable_notifiers => nil
    }.merge(messages)

    @project ||= stub("project", messages)
  end

  def mock_build(messages={})
    messages = {
      :status => :success,
      :successful? => true,
      :output => 'output',
      :project => @project,
      :commit_identifier => '9f6302002d2259c05a64767e0dedb15d280a4848',
      :commit_author => mock("author",
        :name  => 'Nicolás Sanguinetti',
        :email => 'contacto@nicolassanguinetti.info',
        :full  =>'Nicolás Sanguinetti <contacto@nicolassanguinetti.info>'
      ),
      :commited_at => Time.mktime(2008, 7, 24, 17, 15),
      :commit_message => "Add Object#tap for versions of ruby that don't have it"
    }.merge(messages)
    messages[:short_commit_identifier] = messages[:commit_identifier][0..5]
    mock('build', messages)
  end

  def disable_basic_auth!
    Integrity.stub!(:config).and_return(:use_basic_auth => false)
  end

  def enable_basic_auth!
    Integrity.stub!(:config).and_return(:use_basic_auth => true, :admin_username => 'user', :admin_password => 'pass')
  end
end
