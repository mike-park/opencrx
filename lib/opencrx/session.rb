require 'httparty'

module Opencrx
  class HttpError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def to_s
      "#{response.request.last_uri} => #{response.response.inspect}"
    end
  end

  class Session
    include HTTParty

    #debug_output
    headers 'Accept' => 'text/xml', 'Content-Type' => 'text/xml;charset=UTF-8'
    format :xml

    REST_INTERFACE = "/opencrx-rest-CRX"

    def initialize(base_url, user, password)
      self.class.base_uri(base_url + REST_INTERFACE)
      self.class.basic_auth(user, password)
    end

    def get(url, options = {})
      action(:get, url, options)
    end

    def put(url, options = {})
      action(:put, url, options)
    end

    def post(url, options = {})
      action(:post, url, options)
    end

    def delete(url, options = {})
      action(:delete, url, options.merge(headers: {}))
    end

    def action(method, url, options)
      response = self.class.send(method, url, options)
      logger.debug { "\n\nSENT >>>>>>>>>>>>\n#{response.request.inspect}" }
      logger.debug { "\nRECEIVED <<<<<<<<<<<<<<\n#{response.response.body}" }
      code = response.response.code
      case code
        when /^[45]/
          logger.info { response.response }
          logger.info { response.response.body }
          raise HttpError.new(response)
        else
          response
      end
    end

    def logger
      Opencrx.logger
    end
  end
end