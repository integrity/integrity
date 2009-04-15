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
                   :thin      => :boolean,
                   :heroku    => :boolean
    def install(path)
      @root = Pathname(path).expand_path

      if options[:heroku]
        cp_r Pathname(__FILE__).join("../../../config/heroku"), root
        puts post_heroku_install_message
      else
        create_dir_structure
        copy_template_files
        edit_template_files
        puts post_install_message
      end
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
         "Launch Integrity real quick. Database is saved in #{database_path}."
    method_options :config => :optional, :port => :optional
    def launch
      require "thin"
      require "do_sqlite3"

      options[:port] ||= 4567
      config = { :database_uri => "sqlite3://#{ENV["HOME"]}/.integrity.db",
                 :base_uri     => "http://0.0.0.0:#{options[:port]}",
                 :export_directory => "/tmp/integrity-exports"             }
      config.merge!(YAML.load_file(options[:config])) if options[:config]

      migrate_db(config)

      Thin::Server.start("0.0.0.0", options[:port], Integrity::App)
    rescue LoadError => boom
      $stderr << "Make sure thin and do_sqlite3 are insatalled\n\n"
      raise
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

      def post_heroku_install_message
        <<EOF
Your Integrity install is ready to be deployed onto Heroku. Next steps:

  1. git init && git add . && git commit -am "Initial import"
  2. heroku create
  3. git push heroku master
  4. heroku rake db:migrate
EOF
      end

      def post_install_message
        <<EOF
Awesome! Integrity was installed successfully!

To complete the installation, please configure the `database_uri` in
#{root.join("config.yml")} and install the matching DataMapper adapter if
necessary. Then, run `integrity migrate_db #{root.join("config.yml")}

== Notifiers
If you want to enable notifiers, install the gems and then require them
in #{root}/config.ru

For example:

    sudo gem install -s http://gems.github.com foca-integrity-email

And then in #{root}/config.ru add:

    require "notifier/email"

Don't forget to tweak #{root / "config.yml"} to your needs.
EOF
      end

      def copy(source)
        cp(Pathname(__FILE__).dirname.join("../../config", source),
          root.join(File.basename(source).gsub(/\.sample/, "")))
      end
  end
end
