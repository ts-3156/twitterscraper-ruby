require 'net/http'
require 'nokogiri'
require 'date'
require 'json'

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
    USER_AGENT = USER_AGENT_LIST.sample

    INIT_URL = 'https://twitter.com/search?f=tweets&vertical=default&q=__QUERY__&l=__LANG__'
    RELOAD_URL = 'https://twitter.com/i/search/timeline?f=tweets&vertical=' +
        'default&include_available_features=1&include_entities=1&' +
        'reset_error_state=false&src=typd&max_position=__POS__&q=__QUERY__&l=__LANG__'
    INIT_URL_USER = 'https://twitter.com/{u}'
    RELOAD_URL_USER = 'https://twitter.com/i/profiles/show/{u}/timeline/tweets?' +
        'include_available_features=1&include_entities=1&' +
        'max_position={pos}&reset_error_state=false'

    def get_query_url(query, lang, pos, from_user = false)
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

    def query_single_page(query, lang, pos, retries = 30, from_user = false, timeout = 3, headers: [], proxies: [])
      query = query.gsub(' ', '%20').gsub('#', '%23').gsub(':', '%3A').gsub('&', '%26')
      logger.info("Querying #{query}")

      url = get_query_url(query, lang, pos, from_user)
      logger.debug("Scraping tweets from #{url}")

      response = nil
      begin
        proxy = proxies.sample
        logger.info("Using proxy #{proxy}")

        response = Twitterscraper::Http.get(url, headers, proxy, timeout)
      rescue => e
        logger.debug "query_single_page: #{e.inspect}"
        if (retries -= 1) > 0
          logger.info("Retrying... (Attempts left: #{retries - 1})")
          retry
        else
          raise
        end
      end

      html = ''
      json_resp = nil

      if pos
        begin
          json_resp = JSON.parse(response)
          html = json_resp['items_html'] || ''
        rescue => e
          logger.warn("Failed to parse JSON #{e.inspect} while requesting #{url}")
        end
      else
        html = response || ''
      end

      tweets = Tweet.from_html(html)

      if tweets.empty?
        if json_resp && json_resp['has_more_items']
          pos = json_resp['min_position']
        else
          pos = nil
        end
        return [], pos
      end

      if json_resp
        [tweets, json_resp['min_position']]
      elsif from_user
        raise NotImplementedError
      else
        [tweets, "TWEET-#{tweets[-1].tweet_id}-#{tweets[0].tweet_id}"]
      end
    end

    def query_tweets(query, start_date: nil, end_date: nil, limit: 100, threads: 2, lang: '')
      start_date = start_date ? Date.parse(start_date) : Date.parse('2006-3-21')
      end_date = end_date ? Date.parse(end_date) : Date.today
      if start_date == end_date
        raise 'Please specify different values for :start_date and :end_date.'
      elsif start_date > end_date
        raise 'The :start_date must occur before :end_date.'
      end

      # TODO parallel

      pos = nil
      all_tweets = []

      proxies = Twitterscraper::Proxy.get_proxies
      logger.info "Using #{proxies.size} proxies"

      headers = {'User-Agent': USER_AGENT, 'X-Requested-With': 'XMLHttpRequest'}
      logger.info("Headers #{headers}")

      start_date.upto(end_date) do |date|
        break if date == end_date

        queries = query + " since:#{date} until:#{date + 1}"

        while true
          new_tweets, new_pos = query_single_page(queries, lang, pos, headers: headers, proxies: proxies)
          logger.info("Got #{new_tweets.size} tweets")
          logger.debug("new_pos=#{new_pos}")

          unless new_tweets.empty?
            all_tweets.concat(new_tweets)
            all_tweets.uniq! { |t| t.tweet_id }
          end

          break unless new_pos
          break if all_tweets.size >= limit

          pos = new_pos
        end

        break if all_tweets.size >= limit
      end

      all_tweets
    end
  end
end
