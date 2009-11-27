module Integrity
  module SCM
    class Git < Abstract
      def metadata(commit)
        format = "---%nid: %H%nauthor: %an " \
          "<%ae>%nmessage: >-%n  %s%ntimestamp: %ci%n"

        dump = YAML.load(`cd #{dir_for(commit)} && git show -s \
          --pretty=format:"#{format}" #{commit}`)

        dump.update("timestamp" => Time.parse(dump["timestamp"]))
      end

      def head
        `git ls-remote --heads #{uri} #{branch} | cut -f1`.chomp
      end

      private
        def checkout(commit)
          run "git clone #{uri} #{dir_for(commit)}" unless cloned?(commit)
          run "git fetch origin", dir_for(commit)
          run "git checkout origin/#{branch}", dir_for(commit)
          run "git reset --hard #{commit}", dir_for(commit)
        end

        def cloned?(commit)
          dir_for(commit).join(".git").directory?
        end
    end
  end
end
