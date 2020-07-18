module Twitterscraper
  class Template
    def tweets_embedded_html(name, tweets, options)
      path = File.join(File.dirname(__FILE__), 'template/tweets.html.erb')
      template = ERB.new(File.read(path))

      template.result_with_hash(
          chart_name: name,
          chart_data: chart_data(tweets).to_json,
          first_tweet: tweets.sort_by { |t| t.created_at.to_i }[0],
          last_tweet: tweets.sort_by { |t| t.created_at.to_i }[-1],
          tweets: tweets,
          convert_limit: 30,
      )
    end

    def chart_data(tweets)
      data = tweets.each_with_object(Hash.new(0)) do |tweet, memo|
        t = tweet.created_at
        min = (t.min.to_f / 5).floor * 5
        time = Time.new(t.year, t.month, t.day, t.hour, min, 0, '+00:00')
        memo[time.to_i] += 1
      end

      data.sort_by { |k, v| k }.map do |timestamp, count|
        [timestamp * 1000, count]
      end
    end
  end
end
