require 'resolv-replace'
require 'net/http'
require 'nokogiri'
require 'date'
require 'json'
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

    def get_single_page(url, headers, proxies, timeout = 10, retries = 30)
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
      query = query.gsub(' ', '%20').gsub('#', '%23').gsub(':', '%3A').gsub('&', '%26')

      url = build_query_url(query, lang, pos, from_user)
      logger.debug("Scraping tweets from #{url}")

      response = get_single_page(url, headers, proxies)
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

    def query_tweets(query, start_date: nil, end_date: nil, lang: '', limit: 100, threads: 2, proxy: false)
      start_date = start_date ? Date.parse(start_date) : Date.parse('2006-3-21')
      end_date = end_date ? Date.parse(end_date) : Date.today
      if start_date == end_date
        raise 'Please specify different values for :start_date and :end_date.'
      elsif start_date > end_date
        raise ':start_date must occur before :end_date.'
      end

      proxies = proxy ? Twitterscraper::Proxy::Pool.new : []

      date_range = start_date.upto(end_date - 1)
      queries = date_range.map { |date| query + " since:#{date} until:#{date + 1}" }
      threads = queries.size if threads > queries.size
      logger.info("Threads #{threads}")

      headers = {'User-Agent': USER_AGENT_LIST.sample, 'X-Requested-With': 'XMLHttpRequest'}
      logger.info("Headers #{headers}")

      all_tweets = []
      mutex = Mutex.new

      Parallel.each(queries, in_threads: threads) do |query|

        pos = nil

        while true
          new_tweets, new_pos = query_single_page(query, lang, pos, headers: headers, proxies: proxies)
          unless new_tweets.empty?
            mutex.synchronize {
              all_tweets.concat(new_tweets)
              all_tweets.uniq! { |t| t.tweet_id }
            }
          end
          logger.info("Got #{new_tweets.size} tweets (total #{all_tweets.size}) worker=#{Parallel.worker_number}")

          break unless new_pos
          break if all_tweets.size >= limit

          pos = new_pos
        end

        if all_tweets.size >= limit
          logger.info("Reached limit #{all_tweets.size}")
          raise Parallel::Break
        end
      end

      all_tweets.sort_by { |tweet| -tweet.created_at.to_i }
    end
  end
end
