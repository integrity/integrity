module Integrity
  class User
    include DataMapper::Resource

    property :id,       Serial
    property :name,     String, required: true, length: 50
    property :username, String, required: true, length: 50,  unique: true
    property :email,    String, required: true, length: 255, unique: true
    property :image,    String,  default: '/assets/github-user.png'
    property :admin,    Boolean, default: false

    timestamps :at

  end
end