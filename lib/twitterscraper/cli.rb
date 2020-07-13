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
      threads = options['threads'] ? options['threads'].to_i : 2
      tweets = client.query_tweets(options['query'], limit: limit, threads: threads, start_date: options['start_date'], end_date: options['end_date'])
      File.write('tweets.json', generate_json(tweets))
    end

    def options
      @options
    end

    def generate_json(tweets)
      if options['pretty']
        ::JSON.pretty_generate(tweets)
      else
        ::JSON.generate(tweets)
      end
    end

    def parse_options(argv)
      argv.getopts(
          'h',
          'query:',
          'limit:',
          'start_date:',
          'end_date:',
          'threads:',
          'pretty',
      )
    end
  end
end
