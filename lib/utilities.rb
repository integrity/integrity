module Utilities

  def generate_sha1(key = '')
    Digest::SHA1.hexdigest key.to_s
  end

  def timestamp
    Time.now.to_i.to_s
  end

end