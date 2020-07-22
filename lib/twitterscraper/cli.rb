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
          type: options['type'],
          start_date: options['start_date'],
          end_date: options['end_date'],
          lang: options['lang'],
          limit: options['limit'],
          daily_limit: options['daily_limit'],
          order: options['order'],
          threads: options['threads'],
          threads_granularity: options['threads_granularity'],
      }
      client = Twitterscraper::Client.new(cache: options['cache'], proxy: options['proxy'])
      tweets = client.query_tweets(options['query'], query_options)
      export(options['query'], tweets) unless tweets.empty?
    end

    def export(name, tweets)
      options['format'].split(',').map(&:strip).each do |format|
        file = build_output_name(format, options)
        Dir.mkdir(File.dirname(file)) unless File.exist?(File.dirname(file))

        if format == 'json'
          File.write(file, generate_json(tweets))
        elsif format == 'html'
          File.write(file, Template.new.tweets_embedded_html(name, tweets, options))
        else
          puts "Invalid format #{format}"
        end
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
          'type:',
          'query:',
          'start_date:',
          'end_date:',
          'lang:',
          'limit:',
          'daily_limit:',
          'order:',
          'threads:',
          'threads_granularity:',
          'output:',
          'format:',
          'cache:',
          'proxy:',
          'pretty',
          'verbose',
      )

      options['type'] ||= 'search'
      options['start_date'] = Query::OLDEST_DATE if options['start_date'] == 'oldest'
      options['lang'] ||= ''
      options['limit'] = (options['limit'] || 100).to_i
      options['daily_limit'] = options['daily_limit'].to_i if options['daily_limit']
      options['threads'] = (options['threads'] || 10).to_i
      options['threads_granularity'] ||= 'auto'
      options['format'] ||= 'json'
      options['order'] ||= 'desc'

      options['cache'] = options['cache'] != 'false'
      options['proxy'] = options['proxy'] != 'false'

      options
    end

    def build_output_name(format, options)
      query = options['query'].gsub(/[ :?#&]/, '_')
      date = [options['start_date'], options['end_date']].select { |val| val && !val.empty? }.join('_')
      file = [options['type'], 'tweets', date, query].compact.join('_') + '.' + format
      File.join('out', file)
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
