require 'resolv-replace'
require 'net/http'
require 'nokogiri'
require 'date'
require 'json'
require 'erb'
require 'parallel'

module Twitterscraper
  module Query
    include Logger

    USER_AGENT_LIST = [
        'Mozilla/5.0 (Windows; U; Windows NT 6.1; x64; fr; rv:1.9.2.13) Gecko/20101203 Firebird/3.6.13',
        'Mozilla/5.0 (compatible, MSIE 11, Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko',
        'Mozilla/5.0 (Windows; U; Windows NT 6.1; rv:2.2) Gecko/20110201',
        'Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16',
        'Mozilla/5.0 (Windows NT 5.2; RW; rv:7.0a1) Gecko/20091211 SeaMonkey/9.23a1pre',
    ]

    INIT_URL = 'https://twitter.com/search?f=tweets&vertical=default&q=__QUERY__&l=__LANG__'
    RELOAD_URL = 'https://twitter.com/i/search/timeline?f=tweets&vertical=' +
        'default&include_available_features=1&include_entities=1&' +
        'reset_error_state=false&src=typd&max_position=__POS__&q=__QUERY__&l=__LANG__'
    INIT_URL_USER = 'https://twitter.com/__USER__'
    RELOAD_URL_USER = 'https://twitter.com/i/profiles/show/__USER__/timeline/tweets?' +
        'include_available_features=1&include_entities=1&' +
        'max_position=__POS__&reset_error_state=false'

    def build_query_url(query, lang, from_user, pos)
      if from_user
        if pos
          RELOAD_URL_USER.sub('__USER__', query).sub('__POS__', pos.to_s)
        else
          INIT_URL_USER.sub('__USER__', query)
        end
      else
        if pos
          RELOAD_URL.sub('__QUERY__', query).sub('__LANG__', lang.to_s).sub('__POS__', pos)
        else
          INIT_URL.sub('__QUERY__', query).sub('__LANG__', lang.to_s)
        end
      end
    end

    def get_single_page(url, headers, proxies, timeout = 6, retries = 30)
      return nil if stop_requested?
      unless proxies.empty?
        proxy = proxies.sample
        logger.info("Using proxy #{proxy}")
      end
      Http.get(url, headers, proxy, timeout)
    rescue => e
      logger.debug "query_single_page: #{e.inspect}"
      if (retries -= 1) > 0
        logger.info "Retrying... (Attempts left: #{retries - 1})"
        retry
      else
        raise Error.new("#{e.inspect} url=#{url}")
      end
    end

    def parse_single_page(text, html = true)
      return [nil, nil] if text.nil? || text == ''

      if html
        json_resp = nil
        items_html = text
      else
        json_resp = JSON.parse(text)
        items_html = json_resp['items_html'] || ''
        logger.warn json_resp['message'] if json_resp['message'] # Sorry, you are rate limited.
      end

      [items_html, json_resp]
    end

    def query_single_page(query, lang, type, pos, headers: [], proxies: [])
      logger.info "Querying #{query}"
      query = ERB::Util.url_encode(query)

      url = build_query_url(query, lang, type == 'user', pos)
      http_request = lambda do
        logger.debug "Scraping tweets from #{url}"
        get_single_page(url, headers, proxies)
      end

      if cache_enabled?
        client = Cache.new
        if (response = client.read(url))
          logger.debug 'Fetching tweets from cache'
        else
          response = http_request.call
          client.write(url, response) unless stop_requested?
        end
      else
        response = http_request.call
      end
      return [], nil if response.nil? || response.empty?

      html, json_resp = parse_single_page(response, pos.nil?)

      tweets = Tweet.from_html(html)

      if tweets.empty?
        return [], (json_resp && json_resp['has_more_items'] && json_resp['min_position'])
      end

      if json_resp
        [tweets, json_resp['min_position']]
      elsif type
        [tweets, tweets[-1].tweet_id]
      else
        [tweets, "TWEET-#{tweets[-1].tweet_id}-#{tweets[0].tweet_id}"]
      end
    end

    OLDEST_DATE = Date.parse('2006-03-21')

    def validate_options!(queries, type:, start_date:, end_date:, lang:, limit:, threads:)
      query = queries[0]
      if query.nil? || query == ''
        raise Error.new('Please specify a search query.')
      end

      if ERB::Util.url_encode(query).length >= 500
        raise Error.new(':query must be a UTF-8, URL-encoded search query of 500 characters maximum, including operators.')
      end

      if start_date && end_date
        if start_date == end_date
          raise Error.new('Please specify different values for :start_date and :end_date.')
        elsif start_date > end_date
          raise Error.new(':start_date must occur before :end_date.')
        end
      end

      if start_date
        if start_date < OLDEST_DATE
          raise Error.new(":start_date must be greater than or equal to #{OLDEST_DATE}")
        end
      end

      if end_date
        today = Date.today
        if end_date > Date.today
          raise Error.new(":end_date must be less than or equal to today(#{today})")
        end
      end
    end

    def build_queries(query, start_date, end_date)
      if start_date && end_date
        date_range = start_date.upto(end_date - 1)
        date_range.map { |date| query + " since:#{date} until:#{date + 1}" }
      elsif start_date
        [query + " since:#{start_date}"]
      elsif end_date
        [query + " until:#{end_date}"]
      else
        [query]
      end
    end

    def main_loop(query, lang, type, limit, daily_limit, headers, proxies)
      pos = nil
      daily_tweets = []

      while true
        new_tweets, new_pos = query_single_page(query, lang, type, pos, headers: headers, proxies: proxies)
        unless new_tweets.empty?
          daily_tweets.concat(new_tweets)
          daily_tweets.uniq! { |t| t.tweet_id }

          @mutex.synchronize {
            @all_tweets.concat(new_tweets)
            @all_tweets.uniq! { |t| t.tweet_id }
          }
        end
        logger.info "Got #{new_tweets.size} tweets (total #{@all_tweets.size})"

        break unless new_pos
        break if daily_limit && daily_tweets.size >= daily_limit
        break if @all_tweets.size >= limit

        pos = new_pos
      end

      if !@stop_requested && @all_tweets.size >= limit
        logger.warn "The limit you specified has been reached limit=#{limit} tweets=#{@all_tweets.size}"
        @stop_requested = true
      end
    end

    def stop_requested?
      @stop_requested
    end

    def query_tweets(query, type: 'search', start_date: nil, end_date: nil, lang: nil, limit: 100, daily_limit: nil, order: 'desc', threads: 2)
      start_date = Date.parse(start_date) if start_date && start_date.is_a?(String)
      end_date = Date.parse(end_date) if end_date && end_date.is_a?(String)
      queries = build_queries(query, start_date, end_date)
      if threads > queries.size
        logger.warn 'The maximum number of :threads is the number of dates between :start_date and :end_date.'
        threads = queries.size
      end
      if proxy_enabled?
        proxies = Proxy::Pool.new
        logger.debug "Fetch #{proxies.size} proxies"
      else
        proxies = []
        logger.debug 'Proxy disabled'
      end
      logger.debug "Cache #{cache_enabled? ? 'enabled' : 'disabled'}"


      validate_options!(queries, type: type, start_date: start_date, end_date: end_date, lang: lang, limit: limit, threads: threads)

      logger.info "The number of threads #{threads}"

      headers = {'User-Agent': USER_AGENT_LIST.sample, 'X-Requested-With': 'XMLHttpRequest'}
      logger.info "Headers #{headers}"

      @all_tweets = []
      @mutex = Mutex.new
      @stop_requested = false

      if threads > 1
        Thread.abort_on_exception = true
        logger.debug "Set 'Thread.abort_on_exception' to true"

        Parallel.each(queries, in_threads: threads) do |query|
          main_loop(query, lang, type, limit, daily_limit, headers, proxies)
          raise Parallel::Break if stop_requested?
        end
      else
        queries.each do |query|
          main_loop(query, lang, type, limit, daily_limit, headers, proxies)
          break if stop_requested?
        end
      end

      @all_tweets.sort_by { |tweet| (order == 'desc' ? -1 : 1) * tweet.created_at.to_i }
    end

    def search(query, start_date: nil, end_date: nil, lang: '', limit: 100, daily_limit: nil, order: 'desc', threads: 2)
      query_tweets(query, type: 'search', start_date: start_date, end_date: end_date, lang: lang, limit: limit, daily_limit: daily_limit, order: order, threads: threads)
    end

    def user_timeline(screen_name, limit: 100, order: 'desc')
      query_tweets(screen_name, type: 'user', start_date: nil, end_date: nil, lang: nil, limit: limit, daily_limit: nil, order: order, threads: 1)
    end
  end
end
