module Twitterscraper
  class Template
    def tweets_embedded_html(name, tweets, options)
      path = File.join(File.dirname(__FILE__), 'template/tweets.html.erb')
      template = ERB.new(File.read(path))

      tweets = tweets.sort_by { |t| t.created_at.to_i }

      template.result_with_hash(
          chart_name: name,
          chart_data: chart_data(tweets).to_json,
          first_tweet: tweets[0],
          last_tweet: tweets[-1],
          tweets: tweets,
          convert_limit: 30,
      )
    end

    def chart_data(tweets, grouping: 'auto')
      if grouping && tweets.size > 100
        if grouping == 'auto'
          month = 28 * 24 * 60 * 60 # 28 days
          duration = tweets[-1].created_at - tweets[0].created_at

          if duration > 3 * month
            grouping = 'day'
          elsif duration > month || tweets.size > 10000
            grouping = 'hour'
          else
            grouping = 'minute'
          end
        end
      end

      Twitterscraper.logger.info "Chart grouping #{grouping}"

      data = tweets.each_with_object(Hash.new(0)) do |tweet, memo|
        t = tweet.created_at

        if grouping == 'day'
          time = Time.new(t.year, t.month, t.day, 0, 0, 0, '+00:00')
        elsif grouping == 'hour'
          time = Time.new(t.year, t.month, t.day, t.hour, 0, 0, '+00:00')
        elsif grouping == 'minute'
          time = Time.new(t.year, t.month, t.day, t.hour, t.min, 0, '+00:00')
        else
          time = t
        end
        memo[time.to_i] += 1
      end

      data.sort_by { |k, _| k }.map do |timestamp, count|
        [timestamp * 1000, count]
      end
    end
  end
end
