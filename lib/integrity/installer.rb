require File.dirname(__FILE__) + "/../integrity"
require "thor"

module Integrity
  class Installer < Thor
    include FileUtils

    desc "install [PATH]",
       "Copy template files to PATH. Next, go there and edit them."
    def install(path)
      @root = File.expand_path(path)

      create_dir_structure
      copy_template_files
      edit_template_files
      create_db(root / "config.yml")
      after_setup_message
    end

    desc "create_db [CONFIG]",
         "Checks the `database_uri` in CONFIG and creates and bootstraps a database for integrity"
    def create_db(config, direction="up")
      Integrity.new(config)
      migrate_db(direction)
    end

    desc "version",
         "Print the current integrity version"
    def version
      puts Integrity.version
    end

    private
      attr_reader :root

      def migrate_db(direction)
        require "integrity/migrations"

        Integrity.migrate(direction)
      end

      def create_dir_structure
        mkdir_p root
        mkdir_p root / "builds"
        mkdir_p root / "log"
        mkdir_p root / "public" # this one is to play nice with Passenger
        mkdir_p root / "tmp"    # this one is to play nice with Passenger
      end

      def copy_template_files
        cp Integrity.root / "config" / "config.sample.ru",  root / "config.ru"
        cp Integrity.root / "config" / "config.sample.yml", root / "config.yml"
        cp Integrity.root / "config" / "thin.sample.yml",   root / "thin.yml"
      end

      def edit_template_files
        edit_integrity_configuration
        edit_thin_configuration
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
  end
end
