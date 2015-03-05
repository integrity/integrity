module Integrity
  class User
    include DataMapper::Resource

    GITHUB_AVATAR_URL = 'https://avatars3.githubusercontent.com/u/:gh_user_id?v=3&s=120'

    property :id,       Serial
    property :name,     String, length: 50
    property :username, String, length: 50,  unique: true
    property :email,    String, length: 255, unique: true
    property :title,    String, length: 50
    property :image,    String,  default: '/assets/github-user.png'
    property :admin,    Boolean, default: false
    property :gh_uid,   String

    timestamps :at


    def avatar
      gh_uid.present? ? github_avatar : image
    end

    def github_avatar
      GITHUB_AVATAR_URL.gsub(':gh_user_id', gh_uid)
    end
  end
end