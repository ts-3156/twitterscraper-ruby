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

    INIT_URL = 'https://twitter.com/search?f=tweets&vertical=default&q=__QUERY__&l=__LANG__'
    RELOAD_URL = 'https://twitter.com/i/search/timeline?f=tweets&vertical=' +
        'default&include_available_features=1&include_entities=1&' +
        'reset_error_state=false&src=typd&max_position=__POS__&q=__QUERY__&l=__LANG__'
    INIT_URL_USER = 'https://twitter.com/__USER__'
    RELOAD_URL_USER = 'https://twitter.com/i/profiles/show/__USER__/timeline/tweets?' +
        'include_available_features=1&include_entities=1&' +
        'max_position=__POS__&reset_error_state=false'

    def build_query_url(query, lang, type, pos)
      if type.user?
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

    def get_single_page(url, timeout = 6, retries = 30)
      return nil if stop_requested?
      if proxy_enabled?
        proxy = proxies.sample
        logger.info("Using proxy #{proxy}")
      end
      Http.get(url, request_headers, proxy, timeout)
    rescue => e
      logger.debug "get_single_page: #{e.inspect}"
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
      end

      [items_html, json_resp]
    end

    def query_single_page(query, lang, type, pos)
      logger.info "Querying #{query}"
      encoded_query = ERB::Util.url_encode(query)

      url = build_query_url(encoded_query, lang, type, pos)
      http_request = lambda do
        logger.debug "Scraping tweets from url=#{url}"
        get_single_page(url)
      end

      if cache_enabled?
        client = Cache.new
        if (response = client.read(url))
          logger.debug "Fetching tweets from cache url=#{url}"
        else
          response = http_request.call
          client.write(url, response) unless stop_requested?
        end
        if @queries && query == @queries.last && pos.nil?
          logger.debug "Delete a cache query=#{query}"
          client.delete(url)
        end
      else
        response = http_request.call
      end
      return [], nil if response.nil? || response.empty?

      html, json_resp = parse_single_page(response, pos.nil?)

      if json_resp && json_resp['message']
        logger.warn json_resp['message'] # Sorry, you are rate limited.
        @stop_requested = true
        Cache.new.delete(url) if cache_enabled?
      end

      tweets = Tweet.from_html(html)

      if tweets.empty?
        return [], (json_resp && json_resp['has_more_items'] && json_resp['min_position'])
      end

      if json_resp
        [tweets, json_resp['min_position']]
      elsif type.user?
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
    end

    def build_queries(query, start_date, end_date, threads_granularity)
      if start_date && end_date
        if threads_granularity == 'auto'
          threads_granularity = start_date.upto(end_date - 1).to_a.size >= 28 ? 'day' : 'hour'
        end

        if threads_granularity == 'day'
          date_range = start_date.upto(end_date - 1)
          queries = date_range.map { |date| query + " since:#{date} until:#{date + 1}" }
        else
          time = Time.utc(start_date.year, start_date.month, start_date.day, 0, 0, 0)
          end_time = Time.utc(end_date.year, end_date.month, end_date.day, 0, 0, 0)
          queries = []

          while true
            if time < Time.now.utc
              queries << (query + " since:#{time.strftime('%Y-%m-%d_%H:00:00')}_UTC until:#{(time + 3600).strftime('%Y-%m-%d_%H:00:00')}_UTC")
            end
            time += 3600
            break if time >= end_time
          end
        end

        @queries = queries

      elsif start_date
        [query + " since:#{start_date}"]
      elsif end_date
        [query + " until:#{end_date}"]
      else
        [query]
      end
    end

    def main_loop(query, lang, type, limit, daily_limit)
      pos = nil
      daily_tweets = []

      while true
        new_tweets, new_pos = query_single_page(query, lang, type, pos)
        unless new_tweets.empty?
          daily_tweets.concat(new_tweets)
          daily_tweets.uniq! { |t| t.tweet_id }

          @mutex.synchronize {
            @all_tweets.concat(new_tweets)
            @all_tweets.uniq! { |t| t.tweet_id }
            logger.info "Got tweets new=#{new_tweets.size} total=#{daily_tweets.size} all=#{@all_tweets.size}"

            if !@stop_requested && @all_tweets.size >= limit
              logger.warn "The limit you specified has been reached limit=#{limit} tweets=#{@all_tweets.size}"
              @stop_requested = true
            end
          }
        end

        break unless new_pos
        break if @stop_requested
        break if daily_limit && daily_tweets.size >= daily_limit
        break if @all_tweets.size >= limit

        pos = new_pos
      end

      daily_tweets
    end

    def stop_requested?
      @stop_requested
    end

    def query_tweets(query, type: 'search', start_date: nil, end_date: nil, lang: nil, limit: 100, daily_limit: nil, order: 'desc', threads: 10, threads_granularity: 'auto')
      type = Type.new(type)
      if type.search?
        start_date = Date.parse(start_date) if start_date && start_date.is_a?(String)
        end_date = Date.parse(end_date) if end_date && end_date.is_a?(String)
      elsif type.user?
        start_date = nil
        end_date = nil
      end

      queries = build_queries(query, start_date, end_date, threads_granularity)
      if threads > queries.size
        threads = queries.size
      end
      logger.debug "Cache #{cache_enabled? ? 'enabled' : 'disabled'}"

      validate_options!(queries, type: type, start_date: start_date, end_date: end_date, lang: lang, limit: limit, threads: threads)

      logger.info "The number of queries #{queries.size}"
      logger.info "The number of threads #{threads}"

      @all_tweets = []
      @mutex = Mutex.new
      @stop_requested = false

      if threads > 1
        Thread.abort_on_exception = true
        logger.debug "Set 'Thread.abort_on_exception' to true"

        Parallel.each(queries, in_threads: threads) do |query|
          main_loop(query, lang, type, limit, daily_limit)
          raise Parallel::Break if stop_requested?
        end
      else
        queries.each do |query|
          main_loop(query, lang, type, limit, daily_limit)
          break if stop_requested?
        end
      end

      logger.info "Return #{@all_tweets.size} tweets"

      @all_tweets.sort_by { |tweet| (order == 'desc' ? -1 : 1) * tweet.created_at.to_i }
    end

    def search(query, start_date: nil, end_date: nil, lang: '', limit: 100, daily_limit: nil, order: 'desc', threads: 10, threads_granularity: 'auto')
      query_tweets(query, type: 'search', start_date: start_date, end_date: end_date, lang: lang, limit: limit, daily_limit: daily_limit, order: order, threads: threads, threads_granularity: threads_granularity)
    end

    def user_timeline(screen_name, limit: 100, order: 'desc')
      query_tweets(screen_name, type: 'user', start_date: nil, end_date: nil, lang: nil, limit: limit, daily_limit: nil, order: order, threads: 1, threads_granularity: nil)
    end
  end
end
