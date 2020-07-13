module Twitterscraper
  module Template
    module_function

    def tweets_embedded_html(tweets)
      tweets_html = tweets.map { |t| EMBED_TWEET_HTML.sub('__TWEET_URL__', t.tweet_url) }
      EMBED_TWEETS_HTML.sub('__TWEETS__', tweets_html.join)
    end

    EMBED_TWEET_HTML = <<~'HTML'
      <blockquote class="twitter-tweet">
        <a href="__TWEET_URL__"></a>
      </blockquote>
    HTML

    EMBED_TWEETS_HTML = <<~'HTML'
      <html>
        <head>
          <style type=text/css>
            .twitter-tweet {
              margin: 30px auto 0 auto !important;
            }
          </style>
          <script>
            window.twttr = (function(d, s, id) {
              var js, fjs = d.getElementsByTagName(s)[0], t = window.twttr || {};
              if (d.getElementById(id)) return t;
              js = d.createElement(s);
              js.id = id;
              js.src = "https://platform.twitter.com/widgets.js";
              fjs.parentNode.insertBefore(js, fjs);

              t._e = [];
              t.ready = function(f) {
                  t._e.push(f);
              };

              return t;
            }(document, "script", "twitter-wjs"));
          </script>
        </head>
        <body>
          __TWEETS__
        </body>
      </html>
    HTML
  end
end
