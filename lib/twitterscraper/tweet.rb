require 'time'

module Twitterscraper
  class Tweet
    KEYS = [
        :screen_name,
        :name,
        :user_id,
        :tweet_id,
        :text,
        :links,
        :hashtags,
        :image_urls,
        :tweet_url,
        :created_at,
    ]
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
        text = inner_html.xpath("//div[@class[contains(., 'js-tweet-text-container')]]/p[@class[contains(., 'js-tweet-text')]]").first.text
        timestamp = inner_html.xpath("//span[@class[contains(., 'js-short-timestamp')]]").first.attr('data-time').to_i
        new(
            screen_name: html.attr('data-screen-name'),
            name: html.attr('data-name'),
            user_id: html.attr('data-user-id').to_i,
            tweet_id: html.attr('data-tweet-id').to_i,
            text: text,
            links: inner_html.xpath("//a[@class[contains(., 'twitter-timeline-link')]]").map { |elem| elem.attr('data-expanded-url') }.select { |link| link && !link.include?('pic.twitter') },
            hashtags: text.scan(/#\w+/).map { |tag| tag.delete_prefix('#') },
            image_urls: inner_html.xpath("//div[@class[contains(., 'AdaptiveMedia-photoContainer')]]").map { |elem| elem.attr('data-image-url') },
            tweet_url: 'https://twitter.com' + html.attr('data-permalink-path'),
            created_at: Time.at(timestamp, in: '+00:00'),
        )
      end
    end
  end
end
