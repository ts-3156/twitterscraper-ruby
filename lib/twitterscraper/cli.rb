$stdout.sync = true

require 'json'
require 'optparse'
require 'twitterscraper'

module Twitterscraper
  class Cli
    def parse
      @options = parse_options(ARGV)
      initialize_logger
    end

    def run
      print_help || return if print_help?
      print_version || return if print_version?

      query_options = {
          start_date: options['start_date'],
          end_date: options['end_date'],
          lang: options['lang'],
          limit: options['limit'],
          daily_limit: options['daily_limit'],
          threads: options['threads'],
          proxy: options['proxy']
      }
      client = Twitterscraper::Client.new(cache: options['cache'])
      tweets = client.query_tweets(options['query'], query_options)
      export(tweets) unless tweets.empty?
    end

    def export(tweets)
      write_json = lambda { File.write(options['output'], generate_json(tweets)) }

      if options['format'] == 'json'
        write_json.call
      elsif options['format'] == 'html'
        File.write('tweets.html', Template.tweets_embedded_html(tweets))
      else
        write_json.call
      end
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
          'daily_limit:',
          'threads:',
          'output:',
          'format:',
          'cache',
          'proxy',
          'pretty',
          'verbose',
      )

      options['start_date'] = Query::OLDEST_DATE if options['start_date'] == 'oldest'
      options['lang'] ||= ''
      options['limit'] = (options['limit'] || 100).to_i
      options['daily_limit'] = options['daily_limit'].to_i if options['daily_limit']
      options['threads'] = (options['threads'] || 2).to_i
      options['format'] ||= 'json'
      options['output'] ||= "tweets.#{options['format']}"

      options
    end

    def initialize_logger
      Twitterscraper.logger.level = ::Logger::DEBUG if options['verbose']
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
      puts "twitterscraper-#{VERSION}"
    end
  end
end
