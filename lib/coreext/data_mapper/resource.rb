module DataMapper
  module Resource

    module ClassMethods
      def scope(query = :all, *conditions)
        send(query, *conditions)
      end
    end

  end
end