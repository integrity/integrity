require File.dirname(__FILE__) + "/../integrity"
require "thor"

module Integrity
  class Installer < Thor
    include FileUtils

    desc "install [PATH]",
       "Copy template files to PATH for desired deployement strategy
       (either Thin or Passenger). Next, go there and edit them."
    method_options :passenger => :boolean,
                   :thin      => :boolean
    def install(path)
      @root = Pathname(path).expand_path

      create_dir_structure
      copy_template_files
      edit_template_files
      migrate_db(root.join("config.yml"))
      after_setup_message
    end

    desc "migrate_db [CONFIG]",
         "Checks the `database_uri` in CONFIG and migrates the
          database up to the lastest version."
    def migrate_db(config)
      Integrity.new(config)

      require "integrity/migrations"
      Integrity.migrate_db
    end

    desc "launch [CONFIG]",
         "Launch Integrity real quick."
    method_options :config => :optional, :port => 4567
    def launch
      require "thin"
      require "do_sqlite3"

      if File.file?(options[:config].to_s)
        Integrity.new(options[:config])
      else
        DataMapper.setup(:default, "sqlite3::memory:")
      end

      DataMapper.auto_migrate!

      Thin::Server.start("0.0.0.0", options[:port], Integrity::App)
    rescue LoadError => boom
      missing_dependency = boom.message.split("--").last.lstrip
      puts "Please install #{missing_dependency} to launch Integrity"
    end

    private
      attr_reader :root

      def create_dir_structure
        mkdir_p root
        mkdir_p root / "builds"
        mkdir_p root / "log"

        if options[:passenger]
          mkdir_p root / "public"
          mkdir_p root / "tmp"
        end
      end

      def copy_template_files
        copy "config/config.sample.ru"
        copy "config/config.sample.yml"
        copy "config/thin.sample.yml" if options[:thin]
      end

      def edit_template_files
        edit_integrity_configuration
        edit_thin_configuration if options[:thin]
      end

      def edit_integrity_configuration
        config = File.read(root / "config.yml")
        config.gsub! %r(sqlite3:///var/integrity.db), "sqlite3://#{root}/integrity.db"
        config.gsub! %r(/path/to/scm/exports),        "#{root}/builds"
        config.gsub! %r(/var/log),                    "#{root}/log"
        File.open(root / "config.yml", "w") { |f| f.puts config }
      end

      def edit_thin_configuration
        config = File.read(root / "thin.yml")
        config.gsub! %r(/apps/integrity), root
        File.open(root / "thin.yml", 'w') { |f| f.puts config }
      end

      def after_setup_message
        puts
        puts %Q(Awesome! Integrity was installed successfully!)
        puts
        puts %Q(If you want to enable notifiers, install the gems and then require them)
        puts %Q(in #{root}/config.ru)
        puts
        puts %Q(For example:)
        puts
        puts %Q(  sudo gem install -s http://gems.github.com foca-integrity-email)
        puts
        puts %Q(And then in #{root}/config.ru add:)
        puts
        puts %Q(  require "notifier/email")
        puts
        puts %Q(Don't forget to tweak #{root / "config.yml"} to your needs.)
      end

      def copy(path)
        cp(File.dirname(__FILE__) + "/../../#{path}",
          root.join(File.basename(path).gsub(/\.sample/, "")))
      end
  end
end
