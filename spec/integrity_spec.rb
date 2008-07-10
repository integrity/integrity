require File.dirname(__FILE__) + "/spec_helper"

describe Integrity do
  specify "root should point to the directory where all integrity files are located" do
    Integrity.root.should == File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  describe 'When initializing' do
    before(:each) do
      @config = {:database_uri => 'sqlite3:///var/integrity.db'}
      YAML.stub!(:load_file).and_return(@config)
    end

    it 'should load the default configuration file if nothing specified' do
      YAML.should_receive(:load_file).with(Integrity.root + '/../config.yml').
        and_return(@config)
      Integrity.new
    end

    it 'should load the specified configuration file' do
      YAML.should_receive(:load_file).with('/etc/integrity.yml').
        and_return(@config)
      Integrity.new('/etc/integrity.yml')
    end

    it 'should initialize the database connection' do
      DataMapper.should_receive(:setup).with(:default, 'sqlite3:///var/integrity.db')
      Integrity.new
    end
  end
end
