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
    INIT_URL_USER = 'https://twitter.com/{u}'
    RELOAD_URL_USER = 'https://twitter.com/i/profiles/show/{u}/timeline/tweets?' +
        'include_available_features=1&include_entities=1&' +
        'max_position={pos}&reset_error_state=false'

    def build_query_url(query, lang, pos, from_user = false)
      # if from_user
      #   if !pos
      #     INIT_URL_USER.format(u = query)
      #   else
      #     RELOAD_URL_USER.format(u = query, pos = pos)
      #   end
      # end
      if pos
        RELOAD_URL.sub('__QUERY__', query).sub('__LANG__', lang.to_s).sub('__POS__', pos)
      else
        INIT_URL.sub('__QUERY__', query).sub('__LANG__', lang.to_s)
      end
    end

    def get_single_page(url, headers, proxies, timeout = 6, retries = 30)
      return nil if stop_requested?
      Twitterscraper::Http.get(url, headers, proxies.sample, timeout)
    rescue => e
      logger.debug "query_single_page: #{e.inspect}"
      if (retries -= 1) > 0
        logger.info("Retrying... (Attempts left: #{retries - 1})")
        retry
      else
        raise
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

    def query_single_page(query, lang, pos, from_user = false, headers: [], proxies: [])
      logger.info("Querying #{query}")
      query = ERB::Util.url_encode(query)

      url = build_query_url(query, lang, pos, from_user)
      http_request = lambda do
        logger.debug("Scraping tweets from #{url}")
        get_single_page(url, headers, proxies)
      end

      if cache_enabled?
        client = Cache.new
        if (response = client.read(url))
          logger.debug('Fetching tweets from cache')
        else
          response = http_request.call
          client.write(url, response)
        end
      else
        response = http_request.call
      end
      return [], nil if response.nil?

      html, json_resp = parse_single_page(response, pos.nil?)

      tweets = Tweet.from_html(html)

      if tweets.empty?
        return [], (json_resp && json_resp['has_more_items'] && json_resp['min_position'])
      end

      if json_resp
        [tweets, json_resp['min_position']]
      elsif from_user
        raise NotImplementedError
      else
        [tweets, "TWEET-#{tweets[-1].tweet_id}-#{tweets[0].tweet_id}"]
      end
    end

    OLDEST_DATE = Date.parse('2006-03-21')

    def validate_options!(query, start_date:, end_date:, lang:, limit:, threads:, proxy:)
      if query.nil? || query == ''
        raise 'Please specify a search query.'
      end

      if ERB::Util.url_encode(query).length >= 500
        raise ':query must be a UTF-8, URL-encoded search query of 500 characters maximum, including operators.'
      end

      if start_date && end_date
        if start_date == end_date
          raise 'Please specify different values for :start_date and :end_date.'
        elsif start_date > end_date
          raise ':start_date must occur before :end_date.'
        end
      end

      if start_date
        if start_date < OLDEST_DATE
          raise ":start_date must be greater than or equal to #{OLDEST_DATE}"
        end
      end

      if end_date
        today = Date.today
        if end_date > Date.today
          raise ":end_date must be less than or equal to today(#{today})"
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

    def main_loop(query, lang, limit, headers, proxies)
      pos = nil

      while true
        new_tweets, new_pos = query_single_page(query, lang, pos, headers: headers, proxies: proxies)
        unless new_tweets.empty?
          @mutex.synchronize {
            @all_tweets.concat(new_tweets)
            @all_tweets.uniq! { |t| t.tweet_id }
          }
        end
        logger.info("Got #{new_tweets.size} tweets (total #{@all_tweets.size})")

        break unless new_pos
        break if @all_tweets.size >= limit

        pos = new_pos
      end

      if @all_tweets.size >= limit
        logger.info("Limit reached #{@all_tweets.size}")
        @stop_requested = true
      end
    end

    def stop_requested?
      @stop_requested
    end

    def query_tweets(query, start_date: nil, end_date: nil, lang: '', limit: 100, threads: 2, proxy: false)
      start_date = Date.parse(start_date) if start_date && start_date.is_a?(String)
      end_date = Date.parse(end_date) if end_date && end_date.is_a?(String)
      queries = build_queries(query, start_date, end_date)
      threads = queries.size if threads > queries.size
      proxies = proxy ? Twitterscraper::Proxy::Pool.new : []

      validate_options!(queries[0], start_date: start_date, end_date: end_date, lang: lang, limit: limit, threads: threads, proxy: proxy)

      logger.info("The number of threads #{threads}")

      headers = {'User-Agent': USER_AGENT_LIST.sample, 'X-Requested-With': 'XMLHttpRequest'}
      logger.info("Headers #{headers}")

      @all_tweets = []
      @mutex = Mutex.new
      @stop_requested = false

      if threads > 1
        Parallel.each(queries, in_threads: threads) do |query|
          main_loop(query, lang, limit, headers, proxies)
          raise Parallel::Break if stop_requested?
        end
      else
        queries.each do |query|
          main_loop(query, lang, limit, headers, proxies)
          break if stop_requested?
        end
      end

      @all_tweets.sort_by { |tweet| -tweet.created_at.to_i }
    end
  end
end
