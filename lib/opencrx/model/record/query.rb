module Opencrx
  module Model
    class Record
      class << self

        def base_provider
          "provider/CRX/segment/Standard"
        end

        def query(options = {})
          response = Opencrx::session.get(query_url, query: merge_options(options))
          ResultSet.new(response)
        end

        def get(id, options = {})
          item_url = "#{query_url}/#{id}"
          response = Opencrx::session.get(item_url, query: merge_options(options))
          Result.parse(response)
        end

        def query_url
          "/#{BASE_KEY}/#{provider}"
        end

        def provider
          base_provider
        end

        def merge_options(options)
          default_query_options.merge(options)
        end

        def default_query_options
          {}
        end

        def query_type_option
          @query_type_option ||= {
              queryType: Map.model_to_opencrx_query(self)
          }
        end
      end

      # children query
      def query(subtype, options = {})
        response = Opencrx::session.get(subtype_query_url(subtype), query: options)
        ResultSet.new(response)
      end

      def subtype_query_url(subtype)
        "#{attributes['href']}/#{subtype}"
      end
    end
  end
end
