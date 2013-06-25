require 'opencrx/version'
require 'opencrx/session'
require 'opencrx/model'
require 'active_support/core_ext'

module Opencrx
  class << self
    attr_accessor :logger, :session

    def connect(base_url, user, password)
      self.session = Opencrx::Session.new(base_url, user, password)
    end

    def logger
      @logger ||= begin
        logger = Logger.new(STDERR)
        logger.level = Logger::WARN
        logger
      end
    end
  end
end
