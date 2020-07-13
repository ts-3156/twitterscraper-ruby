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
      query_options = {
          start_date: options['start_date'],
          end_date: options['end_date'],
          lang: options['lang'],
          limit: options['limit'],
          threads: options['threads'],
          proxy: options['proxy']
      }
      tweets = client.query_tweets(options['query'], query_options)
      File.write(options['output'], generate_json(tweets))
    end

    def generate_json(tweets)
      if options['pretty']
        ::JSON.pretty_generate(tweets)
      else
        ::JSON.generate(tweets)
      end
    end

    def options
      @options
    end

    def parse_options(argv)
      options = argv.getopts(
          'h',
          'query:',
          'start_date:',
          'end_date:',
          'lang:',
          'limit:',
          'threads:',
          'output:',
          'proxy',
          'pretty',
      )

      options['lang'] ||= ''
      options['limit'] = (options['limit'] || 100).to_i
      options['threads'] = (options['threads'] || 2).to_i
      options['output'] ||= 'tweets.json'

      options
    end
  end
end
