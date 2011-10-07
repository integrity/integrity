module Integrity
  class AuthorStruct < Struct.new(:name, :email)
    def self.parse(string)
      if string =~ /^(.*) <(.*)>$/
        new($1.strip, $2.strip)
      else
        new(string, "not loaded")
      end
    end

    def to_s
      @full ||= "#{name} <#{email}>"
    end

    alias_method :full, :to_s
  end

  class Author < DataMapper::Property::String
    length 65535
    # author is used in project display, do not lazy load it
    lazy   false

    def self.unknown
      AuthorStruct.parse("author not loaded")
    end

    def load(value)
      AuthorStruct.parse(value) unless value.nil?
    end

    def dump(value)
      return nil if value.nil?
      value.to_s
    end

    def typecast(value)
      case value
      when AuthorStruct then value
      when NilClass     then load(nil)
      else load(value.to_s)
      end
    end

    def typecast_to_primitive(value)
      value.to_s
    end

    def primitive?(value)
      return value.nil? || value.is_a?(String) || value.is_a?(AuthorStruct)
    end

    def valid?(value)
      primitive?(value)
    end
  end
end
