require 'twitterscraper/logger'
require 'twitterscraper/proxy'
require 'twitterscraper/http'
require 'twitterscraper/lang'
require 'twitterscraper/cache'
require 'twitterscraper/query'
require 'twitterscraper/client'
require 'twitterscraper/tweet'
require 'twitterscraper/template'
require 'version'

module Twitterscraper
  class Error < StandardError; end

  def self.logger
    @logger ||= ::Logger.new(STDOUT, level: ::Logger::INFO)
  end

  def self.logger=(logger)
    if logger.nil?
      self.logger.level = ::Logger::FATAL
      return self.logger
    end

    @logger = logger
  end
end
