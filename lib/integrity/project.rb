require 'dm-validations'
require 'dm-types'

module Integrity
  class Project
    include DataMapper::Resource

    property :id,       Integer,  :serial => true
    property :name,     String,   :nullable => false
    property :uri,      URI,      :nullable => false
    property :branch,   String,   :nullable => false, :default => "master"
    property :command,  String,   :nullable => false, :default => "rake"
    property :public,   Boolean,  :default => true

    def build
      Builder.new(uri, branch, command).build
    end
  end
end
