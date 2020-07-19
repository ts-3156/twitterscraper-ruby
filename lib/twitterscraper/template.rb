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

    def chart_data(tweets, trimming: true, smoothing: true)
      min_interval = 5

      data = tweets.each_with_object(Hash.new(0)) do |tweet, memo|
        t = tweet.created_at
        min = (t.min.to_f / min_interval).floor * min_interval
        time = Time.new(t.year, t.month, t.day, t.hour, min, 0, '+00:00')
        memo[time.to_i] += 1
      end

      if false && trimming
        data.keys.sort.each.with_index do |timestamp, i|
          break if data.size - 1 == i
          if data[i] == 0 && data[i + 1] == 0
            data.delete(timestamp)
          end
        end
      end

      if false && smoothing
        time = data.keys.min
        max_time = data.keys.max
        sec_interval = 60 * min_interval

        while true
          next_time = time + sec_interval
          break if next_time + sec_interval > max_time

          unless data.has_key?(next_time)
            data[next_time] = (data[time] + data[next_time + sec_interval]) / 2
          end
          time = next_time
        end
      end

      data.sort_by { |k, _| k }.map do |timestamp, count|
        [timestamp * 1000, count]
      end
    end
  end
end
