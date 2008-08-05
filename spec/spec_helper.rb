require File.dirname(__FILE__) + "/../lib/integrity"
$:.unshift Integrity.root / "vendor/rspec_hpricot_matchers/lib"

require 'spec'
require 'spec/interop/test'
require 'sinatra'
require 'sinatra/test/unit'
require 'rspec_hpricot_matchers'
require 'haml'

module FormFieldHpricotMatchers
  # TODO: Add support for selects
  # TODO: Test with anything that isn't an input[type=text]
  class HaveField
    include RspecHpricotMatchers
    
    def initialize(id, type, tagname)
      @tagname = tagname
      @type = type
      @id = id
      @tag_matcher = have_tag("#{@tagname}##{@id}", @tagname == "textarea" ? @value : nil)
      @label_set = true # always check for a label, unless explicitly told not to
    end
    
    def named(name)
      @name_set = true
      @name = name
      self
    end
    
    def with_label(label)
      @label = label
      self
    end
    
    def without_label
      @label_set = false
      self
    end
    
    def with_value(value)
      @value_set = true
      @value = value
      self
    end
    
    def checked
      @checked = "checked"
      self
    end
    
    def unchecked
      @checked = ""
      self
    end
    
    def matches?(actual)
      (@label_set ? have_tag("label[@for=#{@id}]", @label).matches?(actual) : true) &&
      @tag_matcher.matches?(actual) do |field|
        field["type"].should == @type if @type
        field["name"].should == @name if @name_set
        field["value"].should == @value if @value_set && @tagname == "input"
        field["checked"].should == @checked if @checked
      end
    end
    
    def failure_message
      attrs = [
        "id ##{@id}",
        @name  && "name '#{@name}'",
        @type  && "type '#{@type}'",
        @label && "labelled '#{@label}'",
        @value && "value '#{@value}'"
      ].compact.join(", ")
      "You expected a #{@tagname}#{@type ? " (#{@type})" : ""} with #{attrs} but found none.\n\n#{@tag_matcher.failure_message}"
    end
  end
  
  def have_field(id, type="text", tagname="input")
    HaveField.new(id, type, tagname)
  end
  
  def have_textfield(id)
    have_field(id)
  end
  
  def have_password(id)
    have_field(id, "password")
  end
  
  def have_checkbox(id)
    have_field(id, "checkbox")
  end

  def have_checkbox(id)
    have_field(id, "checkbox")
  end

  def have_textarea(id)
    have_field(id, nil, "textarea")
  end
end

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
      :output => "the output"
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
