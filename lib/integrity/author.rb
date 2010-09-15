module Integrity
  class Author < DataMapper::Property::String
    length      65535
    lazy      true

    class AuthorStruct < Struct.new(:name, :email)
      def self.parse(string)
        if string =~ /^(.*) <(.*)>$/
          new($1.strip, $2.strip)
        else
          new(string, "unknown")
        end
      end

      def to_s
        @full ||= "#{name} <#{email}>"
      end

      alias_method :full, :to_s
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
      when NilClass     then load(nil, property)
      else load(value.to_s, property)
      end
    end
  end
end
