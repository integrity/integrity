module Integrity
  module SCM
    class Git
      # From the git-pull man page:
      #
      # GIT URLS
      #   One of the following notations can be used to name the remote repository:
      #
      #     rsync://host.xz/path/to/repo.git/
      #     http://host.xz/path/to/repo.git/
      #     git://host.xz/~user/path/to/repo.git/
      #     ssh://[user@]host.xz[:port]/path/to/repo.git/
      #     ssh://[user@]host.xz/path/to/repo.git/
      #     ssh://[user@]host.xz/~user/path/to/repo.git/
      #     ssh://[user@]host.xz/~/path/to/repo.git
      # 
      #   SSH is the default transport protocol over the network. You can optionally 
      #   specify which user to log-in as, and an alternate, scp-like syntax is also 
      #   supported
      #
      #   Both syntaxes support username expansion, as does the native git protocol, 
      #   but only the former supports port specification. The following three are 
      #   identical to the last three above, respectively:
      #
      #     [user@]host.xz:/path/to/repo.git/
      #     [user@]host.xz:~user/path/to/repo.git/
      #     [user@]host.xz:path/to/repo.git
      #
      class URI
        def initialize(uri_string)
          @uri = Addressable::URI.parse(uri_string)
        end
    
        def working_tree_path
          strip_extension(path).gsub("/", "-")
        end
    
      private
    
        def strip_extension(string)
          uri = Pathname.new(string)
          if uri.extname.any?
            uri = Pathname.new(string)
            string.gsub(Regexp.new("#{uri.extname}\/?"), "")
          else
            string
          end
        end
    
        def path
          path = @uri.path
          path.gsub(/\~[a-zA-Z0-9]*\//, "").gsub(/^\//, "")
        end
      end
    end
  end
end
