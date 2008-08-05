module Sinatra
  class EventContext
    def params
      @params ||= ParamsParser.new(@route_params.merge(@request.params)).to_hash
    end
    
    private
    
    class ParamsParser
      attr_reader :hash
      
      def initialize(hash)
        @hash = nested(hash)
      end
      
      alias :to_hash :hash
      
      protected
      
        def nested(hash)
          hash.inject(indifferent_hash) do |par, (key,val)|
            if key =~ /([^\[]+)\[([^\]]+)\](.*)/ # a[b] || a[b][c] ($1 == a, $2 == b, $3 == [c])
              par[$1] ||= indifferent_hash
              par[$1].merge_recursive nested("#{$2}#{$3}" => val)
            else
              par[key] = val
            end
            par
          end
        end

        def indifferent_hash
          Hash.new {|h,k| h[k.to_s] if Symbol === k}
        end
    end
  end
end

class Hash
  def merge_recursive(other)
    update(other) do |key, old_value, new_value|
      if Hash === old_value && Hash === new_value
        old_value.merge_recursive(new_value)
      else
        new_value
      end
    end
  end
end
