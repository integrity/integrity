require "thor"
require File.dirname(__FILE__) + "/../integrity"

module Integrity
  class Installer < Thor
    include FileUtils

    def self.database_path
      File.join(ENV["HOME"], ".integrity.sqlite3")
    end
    private_class_method :database_path

    desc "install [PATH]",
       "Copy template files to PATH for desired deployement strategy
       (either Thin, Passenger or Heroku). Next, go there and edit them."
    method_options :passenger => :boolean,
                   :thin      => :boolean
    def install(path)
      @root = Pathname(path).expand_path

      create_dir_structure
      copy_template_files
      edit_template_files
      puts post_install_message
    end

    desc "migrate_db [CONFIG]",
         "Checks the `database_uri` in CONFIG and migrates the
          database up to the lastest version."
    def migrate_db(config)
      Integrity.new(config)

      require "integrity/migrations"
      Integrity.migrate_db
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
        copy "config.sample.ru"
        copy "config.sample.yml"
        copy "thin.sample.yml" if options[:thin]
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

      def post_install_message
        <<EOF
Awesome! Integrity was installed successfully!

To complete the installation, please configure the `database_uri` in
#{root.join("config.yml")} and install the matching DataMapper adapter if
necessary. Then, run `integrity migrate_db #{root.join("config.yml")}`

Please go to <http://integrityapp.com/#notifiers> for notifiers setup
instructions.
EOF
      end

      def copy(source)
        cp(Pathname(__FILE__).dirname.join("../../config", source),
          root.join(File.basename(source).gsub(/\.sample/, "")))
      end
  end
end
