$stdout.sync = true

require 'json'
require 'optparse'
require 'twitterscraper'

module Twitterscraper
  class Cli
    def parse
      @options = parse_options(ARGV)
    end

    def run
      client = Twitterscraper::Client.new
      limit = options['limit'] ? options['limit'].to_i : 100
      tweets = client.query_tweets(options['query'], limit: limit, start_date: options['start_date'], end_date: options['end_date'])
      File.write('tweets.json', ::JSON.dump(tweets))
    end

    def options
      @options
    end

    def parse_options(argv)
      argv.getopts(
          'h',
          'query:',
          'limit:',
          'start_date:',
          'end_date:',
      )
    end
  end
end
