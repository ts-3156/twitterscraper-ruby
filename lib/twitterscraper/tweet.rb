require 'time'

module Twitterscraper
  class Tweet
    KEYS = [
        :screen_name,
        :name,
        :user_id,
        :profile_image_url,
        :tweet_id,
        :text,
        :links,
        :hashtags,
        :image_urls,
        :video_url,
        :has_media,
        :likes,
        :retweets,
        :replies,
        :is_replied,
        :is_reply_to,
        :parent_tweet_id,
        :reply_to_users,
        :tweet_url,
        :timestamp,
        :created_at,
    ]
    attr_reader *KEYS

    def initialize(attrs)
      attrs.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def attrs
      KEYS.map do |key|
        [key, send(key)]
      end.to_h
    end

    def to_json(options = {})
      attrs.to_json
    end

    class << self
      def from_json(text)
        json = JSON.parse(text)
        json.map do |tweet|
          tweet['created_at'] = Time.parse(tweet['created_at'])
          new(tweet)
        end
      end

      # .js-stream-item
      #   .js-stream-tweet{data: {screen-name:, tweet-id:}}
      #     .stream-item-header
      #     .js-tweet-text-container
      #     .stream-item-footer
      def from_html(text)
        html = Nokogiri::HTML(text)
        from_tweets_html(html.xpath("//li[@class[contains(., 'js-stream-item')]]/div[@class[contains(., 'js-stream-tweet')]]"))
      end

      def from_tweets_html(html)
        html.map do |tweet|
          from_tweet_html(tweet)
        end.compact
      end

      def from_tweet_html(html)
        screen_name = html.attr('data-screen-name')
        tweet_id = html.attr('data-tweet-id')&.to_i

        unless html.to_s.include?('js-tweet-text-container')
          Twitterscraper.logger.warn "html doesn't include div.js-tweet-text-container url=https://twitter.com/#{screen_name}/status/#{tweet_id}"
          return nil
        end

        inner_html = Nokogiri::HTML(html.inner_html)

        profile_image_url = inner_html.xpath("//img[@class[contains(., 'js-action-profile-avatar')]]").first.attr('src').gsub(/_bigger/, '')
        text = inner_html.xpath("//div[@class[contains(., 'js-tweet-text-container')]]/p[@class[contains(., 'js-tweet-text')]]").first.text
        links = inner_html.xpath("//a[@class[contains(., 'twitter-timeline-link')]]").map { |elem| elem.attr('data-expanded-url') }.select { |link| link && !link.include?('pic.twitter') }
        image_urls = inner_html.xpath("//div[@class[contains(., 'AdaptiveMedia-photoContainer')]]").map { |elem| elem.attr('data-image-url') }
        video_url = inner_html.xpath("//div[@class[contains(., 'PlayableMedia-container')]]/a").map { |elem| elem.attr('href') }[0]
        has_media = !image_urls.empty? || (video_url && !video_url.empty?)

        actions = inner_html.xpath("//div[@class[contains(., 'ProfileTweet-actionCountList')]]")
        likes = actions.xpath("//span[@class[contains(., 'ProfileTweet-action--favorite')]]/span[@class[contains(., 'ProfileTweet-actionCount')]]").first.attr('data-tweet-stat-count').to_i || 0
        retweets = actions.xpath("//span[@class[contains(., 'ProfileTweet-action--retweet')]]/span[@class[contains(., 'ProfileTweet-actionCount')]]").first.attr('data-tweet-stat-count').to_i || 0
        replies = actions.xpath("//span[@class[contains(., 'ProfileTweet-action--reply u-hiddenVisually')]]/span[@class[contains(., 'ProfileTweet-actionCount')]]").first.attr('data-tweet-stat-count').to_i || 0
        is_replied = replies != 0

        parent_tweet_id = inner_html.xpath('//*[@data-conversation-id]').first.attr('data-conversation-id').to_i
        if tweet_id == parent_tweet_id
          is_reply_to = false
          parent_tweet_id = nil
          reply_to_users = []
        else
          is_reply_to = true
          reply_to_users = inner_html.xpath("//div[@class[contains(., 'ReplyingToContextBelowAuthor')]]/a").map { |user| {screen_name: user.text.delete_prefix('@'), user_id: user.attr('data-user-id')} }
        end

        timestamp = inner_html.xpath("//span[@class[contains(., 'js-short-timestamp')]]").first.attr('data-time').to_i
        new(
            screen_name: screen_name,
            name: html.attr('data-name'),
            user_id: html.attr('data-user-id').to_i,
            profile_image_url: profile_image_url,
            tweet_id: tweet_id,
            text: text,
            links: links,
            hashtags: text.scan(/#\w+/).map { |tag| tag.delete_prefix('#') },
            image_urls: image_urls,
            video_url: video_url,
            has_media: has_media,
            likes: likes,
            retweets: retweets,
            replies: replies,
            is_replied: is_replied,
            is_reply_to: is_reply_to,
            parent_tweet_id: parent_tweet_id,
            reply_to_users: reply_to_users,
            tweet_url: 'https://twitter.com' + html.attr('data-permalink-path'),
            timestamp: timestamp,
            created_at: Time.at(timestamp, in: '+00:00'),
        )
      end
    end
  end
end
