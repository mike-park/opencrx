require "opencrx/version"
require 'rest_client'
require 'logger'
require 'nokogiri'
require 'builder'

module Opencrx

  def self.agent
    @@agent
  end

  def self.agent=(object)
    @@agent = object
  end

  class Agent
    attr_reader :base_url

    def initialize(url)
      @base_url = url
      RestClient.log = Logger.new STDOUT
      Opencrx::agent = self
    end

    def contacts
      xtra = {params: {position: 43-24, xsize: 43, xqueryType: 'org:opencrx:kernel:account1:Contact'}}
      xml = parse RestClient.get(contacts_url, params.merge(xtra))
      xml.search("//org.openmdx.kernel.ResultSet").first.children.map { |n| n.name }
    end

    def contact(id)
      response = RestClient.get(contacts_url + "/#{id}", params)
      parse response
    end

    def parse(response)
      Nokogiri.XML(response)
    end

    def contacts_url
      base_url + "/opencrx-rest-CRX/org.opencrx.kernel.account1/provider/CRX/segment/Standard/account"
    end

    def post(suffix, xml)
      parse RestClient.post(full_url(suffix), xml, params.merge(content_type: :xml)) do |response, request, result, &block|
        case response.code
          when 200
            response
          when 400
            puts "FAILED"
            ap parse(response)
          else
            response.return!(request, result, &block)
        end
      end
    end

    def put(suffix, xml)
      parse RestClient.put(full_url(suffix), xml, params.merge(content_type: :xml)) do |response, request, result, &block|
        case response.code
          when 200
            response
          when 400
            puts "FAILED"
            ap parse(response)
          else
            response.return!(request, result, &block)
        end
      end

    end

    def get(suffix)
      parse RestClient.get(full_url(suffix), params.merge(content_type: :xml)) do |response, request, result, &block|
        case response.code
          when 200
            response
          when 400
            puts "FAILED"
            ap parse(response)
          else
            response.return!(request, result, &block)
        end
      end
    end

    def full_url(suffix)
      base_url + suffix
    end

    def params
      {accept: :xml, content_type: :xml}
    end
  end

  class Contact
    attr_reader :agent

    SUFFIX = "/opencrx-rest-CRX/org.opencrx.kernel.account1/provider/CRX/segment/Standard/account"

    def initialize(agent)
      @agent = agent
    end

    def get(id)
      agent.get(SUFFIX + "/#{id}")
    end

    def updateX
      builder = Builder::XmlMarkup.new
      xml = '<?xml version="1.0" encoding="UTF-8"?>'
      xml += builder.tag!('org.opencrx.kernel.account1.Contact') do |b|
        b.salutation('ruby code')
      end
      agent.put(SUFFIX + "/-5uS0P6.Ed26mZW37tpC6Q", xml)
    end

    def save
      builder = Builder::XmlMarkup.new
      xml = '<?xml version="1.0" encoding="UTF-8"?>'
      xml += builder.tag!('org.opencrx.kernel.account1.Contact') do |b|
        b.lastName('ruby code')
      end
      agent.post(SUFFIX, xml)
    end
  end
end
