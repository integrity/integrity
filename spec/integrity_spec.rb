require File.dirname(__FILE__) + "/spec_helper"

describe Integrity do
  specify "root should point to the directory where all integrity files are located" do
    Integrity.root.should == File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  specify 'default configuration' do
    Integrity.default_configuration.should == {
      :database_uri => 'sqlite3::memory:',
      :export_directory => Integrity.root / 'exports',
      :base_url => 'http://localhost:4567'
    }
  end

  describe 'When initializing' do
    before(:each) do
      @config = {:database_uri => 'sqlite3:///var/integrity.db'}
      YAML.stub!(:load_file).and_return(@config)
      DataMapper.stub!(:setup).with(:default, anything)
    end

    after(:each) do
      Integrity.instance_variable_set(:@config, nil)
    end

    it 'should load the default configuration file if nothing specified' do
      YAML.should_receive(:load_file).with(Integrity.root + '/config/config.yml').
        and_return(@config)
      Integrity.instance_variable_set(:@config, nil)
      Integrity.new
    end

    it 'should load the specified configuration file' do
      YAML.should_receive(:load_file).with('/etc/integrity.yml').
        and_return(@config)
      Integrity.new('/etc/integrity.yml')
    end

    it "should not blow up if the configuration file isn't present" do
      YAML.stub!(:load_file).and_raise(Errno::ENOENT)
      lambda { Integrity.new }.should_not raise_error(Errno::ENOENT)
    end

    it 'should initialize the database connection' do
      DataMapper.should_receive(:setup).with(:default, 'sqlite3:///var/integrity.db')
      Integrity.new
    end
  end
end
