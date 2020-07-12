require 'time'

module Twitterscraper
  class Tweet
    KEYS = [:screen_name, :name, :user_id, :tweet_id, :tweet_url, :created_at, :text]
    attr_reader *KEYS

    def initialize(attrs)
      attrs.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def to_json(options = {})
      KEYS.map do |key|
        [key, send(key)]
      end.to_h.to_json
    end

    class << self
      def from_html(text)
        html = Nokogiri::HTML(text)
        from_tweets_html(html.xpath("//li[@class[contains(., 'js-stream-item')]]/div[@class[contains(., 'js-stream-tweet')]]"))
      end

      def from_tweets_html(html)
        html.map do |tweet|
          from_tweet_html(tweet)
        end
      end

      def from_tweet_html(html)
        inner_html = Nokogiri::HTML(html.inner_html)
        timestamp = inner_html.xpath("//span[@class[contains(., 'js-short-timestamp')]]").first.attr('data-time').to_i
        new(
            screen_name: html.attr('data-screen-name'),
            name: html.attr('data-name'),
            user_id: html.attr('data-user-id').to_i,
            tweet_id: html.attr('data-tweet-id').to_i,
            tweet_url: 'https://twitter.com' + html.attr('data-permalink-path'),
            created_at: Time.at(timestamp, in: '+00:00'),
            text: inner_html.xpath("//div[@class[contains(., 'js-tweet-text-container')]]/p[@class[contains(., 'js-tweet-text')]]").first.text,
        )
      end
    end
  end
end
