require "opencrx/version"
require 'httparty'
require 'logger'
require 'nokogiri'
require 'builder'
require 'active_support/inflector'

module Opencrx

  @@session = nil

  def self.connect(base_url, user, password)
    self.session = Opencrx::Session.new(base_url, user, password)
  end

  def self.session
    @@session
  end

  def self.session=(object)
    @@session = object
  end

  class Session
    include HTTParty

    #debug_output
    headers 'Accept' => 'text/xml', 'Content-Type' => 'text/xml'
    format :xml

    def initialize(base_url, user, password)
      self.class.base_uri(base_url)
      self.class.basic_auth(user, password)
    end

    def get(suffix, options = {})
      self.class.get(suffix, options)
    end
  end

  module Account
    SUFFIX = "/opencrx-rest-CRX/org.opencrx.kernel.account1/provider/CRX/segment/Standard/account"
    KEY = Regexp.new('^org.opencrx.kernel.account1.(.*)$')
    RESULTSET = 'org.openmdx.kernel.ResultSet'

    def self.get(id)
      response = session.get(SUFFIX + "/#{id}")
      build_record(response)
    end

    def self.build_record(hash)
      puts "Expected a single key, got [#{hash.keys}]" unless hash.keys.length == 1
      key = hash.keys.first
      key.match(KEY)
      klass_name = $1
      if (klass = ActiveSupport::Inflector.safe_constantize("Opencrx::Account::#{klass_name}"))
        klass.new(hash)
      else
        puts "Dont understand record type [#{klass_name}]"
      end
    end

    def self.failure(response)
      ap response.request
      ap response.response
      ap response.parsed_response
      nil
    end

    def self.query(params = {})
      response = session.get(SUFFIX, query: params)
      key = response.keys.first
      if key == RESULTSET
        parse_resultset(response[key])
      else
        failure(response)
      end
    end

    def self.parse_resultset(hash)
      hash.map do |key, value|
        next if %w(href hasMore).include? key
        build_record(key => value)
      end.compact
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

    def self.session
      Opencrx::session
    end

    class AccountRecord < SimpleDelegator
      attr_reader :key

      def initialize(attributes)
        @key = attributes.keys.first
        super attributes[@key]
      end
    end

    class Contact < AccountRecord;
    end
    class Group < AccountRecord;
    end
    class UnspecifiedAccount < AccountRecord;
    end
    class LegalEntity < AccountRecord;
    end
  end

end
