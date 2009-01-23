module Integrity
  class Author < DataMapper::Type
    primitive String
    size      65535
    lazy      true

    class AuthorStruct < Struct.new(:name, :email)
      def self.parse(string)
        raise ArgumentError.new("Invalid author string") unless string =~ /^(.*) <(.*)>$/

        new($1.strip, $2.strip)
      end

      def to_s
        @full ||= "#{name} <#{email}>"
      end

      alias_method :full, :to_s
    end

    def self.load(value, property)
      AuthorStruct.parse(value)
    end

    def self.dump(value, property)
      return nil if value.nil?

      value.to_s
    end

    def self.typecast(value, property)
      case value
      when AuthorStruct then value
      when NilClass     then load(nil, property)
      else load(value.to_s, property)
      end
    end
  end
end
