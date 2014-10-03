class Commands

  class << self

    # curl -H "Authorization: token put-token-here" https://api.github.com/repos/ConsultingMD/tp/contents/.integrity.erb
    def build_template(token, acct, repo)
      render :build_template, token, acct, repo
    end

    def docker_build(token)
      render [:docker, :build], token
    end

    def docker_run(image, token = nil)
      render [:docker, :run, image], token
    end

    def docker_run_image(mysql, token)
      render [:docker, :run, :image], mysql, token
    end

    def docker_run_mysql(uuid)
      render [:docker, :run, :mysql], uuid
    end

    def render(key, *args)
      config(key) % args
    end

    private

    def config(key)
      case key
        when Symbol then RConfig.commands[key]
        when Array  then RConfig.commands(*key)
      end
    end

  end

end