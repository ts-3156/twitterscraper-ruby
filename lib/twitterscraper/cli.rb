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
      print_help || return if print_help?
      print_version || return if print_version?

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
          'help',
          'v',
          'version',
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

    def print_help?
      options['h'] || options['help']
    end

    def print_help
      puts <<~'SHELL'
        Usage:
          twitterscraper --query KEYWORD --limit 100 --threads 10 --start_date 2020-07-01 --end_date 2020-07-10 --lang ja --proxy --output output.json
      SHELL
    end

    def print_version?
      options['v'] || options['version']
    end

    def print_version
      puts "twitterscraper-#{Twitterscraper::VERSION}"
    end
  end
end
