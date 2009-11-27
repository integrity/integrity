module Integrity
  module SCM
    class Svn < Abstract
      def metadata(rev)
        dump = `svn log --non-interactive --revision #{rev} #{uri}`.split("\n")
        meta = dump[1].split(" | ")

        { "id"        => rev,
          "message"   => dump[3],
          "author"    => meta[1],
          "timestamp" => Time.parse(meta[2]) }
      end

      def head
        `svn info #{uri}`.split("\n").detect { |l| l =~ /^Revision: (\d+)/ }
        $1.to_s
      end

      private
        def checkout(rev)
          run "svn co -q #{uri} #{dir_for(rev)}" unless checked_out?(rev)
          run "svn up -q -r#{rev}", dir_for(rev)
        end

        def checked_out?(rev)
          dir_for(rev).join(".svn").directory?
        end
    end
  end
end
