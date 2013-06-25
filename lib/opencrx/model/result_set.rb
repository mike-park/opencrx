module Opencrx
  module Model
    class ResultSet < Array
      KEY = 'org.openmdx.kernel.ResultSet'

      attr_reader :response

      def initialize(response)
        @response = response
        unless response.has_key?(KEY)
          raise "Response missing #{KEY}\n#{response.body}"
        end
        super(results)
      end

      def more?
        response[KEY]['hasMore']
      end

      def results
        result_set.map do |key, value|
          #puts "SET: #{key}"
          #ap value
          case value
            when Array
              value.map { |v| Result.parse(key => v) }
            when Hash
              Result.parse(key => value)
            else
              # ignore
          end
        end.flatten.compact
      end

      def result_set
        response[KEY] || []
      end
    end
  end
end