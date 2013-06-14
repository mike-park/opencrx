require "opencrx/version"
require 'httparty'
require 'active_support/inflector'
require 'active_support/core_ext'

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

    def get(url, options = {})
      self.class.get(url, options)
    end

    def put(url, options = {})
      self.class.put(url, options)
    end

    def post(url, options = {})
      self.class.post(url, options)
    end
  end

  module Account
    SUFFIX = "/opencrx-rest-CRX/org.opencrx.kernel.account1/provider/CRX/segment/Standard/account"
    KEY = Regexp.new('^org.opencrx.kernel.account1.(.*)$')
    RESULTSET = 'org.openmdx.kernel.ResultSet'

    def self.get(id)
      response = session.get(SUFFIX + "/#{id}")
      #ap Nokogiri.XML(response.body)
      build_record(response)
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

    def self.post(xml)
      build_record session.post(SUFFIX, body: xml)
    end

    def self.put(url, xml)
      build_record session.put(url, body: xml)
    end

    def self.session
      Opencrx::session
    end

    def self.parse_resultset(hash)
      hash.map do |key, value|
        next if %w(href hasMore).include? key
        build_record(key => value)
      end.compact
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

    class AccountRecord < SimpleDelegator
      BASEKEY = "org.opencrx.kernel.account1"

      def initialize(attributes)
        attributes = attributes[key] if attributes.has_key? key
        super attributes
      end

      def key
        "#{BASEKEY}.#{ActiveSupport::Inflector.demodulize self.class}"
      end

      def save
        if has_key?('href')
          Opencrx::Account.put(fetch('href'), xml)
        else
          Opencrx::Account.post(xml)
        end
      end

      def xml
        __getobj__.except('owner', 'owningUser', 'owningGroup', 'href', 'version').to_xml(root: key)
      end
    end

    class Contact < AccountRecord
    end
    class Group < AccountRecord
    end
    class UnspecifiedAccount < AccountRecord
    end
    class LegalEntity < AccountRecord
    end
  end

end
