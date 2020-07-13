# twitterscraper-ruby

[![Gem Version](https://badge.fury.io/rb/twitterscraper-ruby.svg)](https://badge.fury.io/rb/twitterscraper-ruby)

A gem to scrape https://twitter.com/search. This gem is inspired by [taspinar/twitterscraper](https://github.com/taspinar/twitterscraper).


## Twitter Search API vs. twitterscraper-ruby

### Twitter Search API

- The number of tweets: 180 - 450 requests/15 minutes (18,000 - 45,000 tweets/15 minutes)
- The time window: the past 7 days

### twitterscraper-ruby

- The number of tweets: Unlimited
- The time window: from 2006-3-21 to today


## Installation

First install the library:

```shell script
$ gem install twitterscraper-ruby
````
    

## Usage

Command-line interface:

```shell script
$ twitterscraper --query KEYWORD --start_date 2020-06-01 --end_date 2020-06-30 --lang ja \
      --limit 100 --threads 10 --proxy --output output.json
```

From Within Ruby:

```ruby
require 'twitterscraper'

options = {
  start_date: '2020-06-01',
  end_date:   '2020-06-30',
  lang:       'ja',
  limit:      100,
  threads:    10,
  proxy:      true
}

client = Twitterscraper::Client.new
tweets = client.query_tweets(KEYWORD, options)

tweets.each do |tweet|
  puts tweet.tweet_id
  puts tweet.text
  puts tweet.tweet_url
  puts tweet.created_at

  hash = tweet.attrs
  puts hash.keys
end
```


## Attributes

### Tweet

- screen_name
- name
- user_id
- tweet_id
- text
- links
- hashtags
- image_urls
- video_url
- has_media
- likes
- retweets
- replies
- is_replied
- is_reply_to
- parent_tweet_id
- reply_to_users
- tweet_url
- created_at


## Search operators

| Operator | Finds Tweets... |
| ------------- | ------------- |
| watching now | containing both "watching" and "now". This is the default operator. |
| "happy hour" | containing the exact phrase "happy hour". |
| love OR hate | containing either "love" or "hate" (or both). |
| beer -root | containing "beer" but not "root". |
| #haiku | containing the hashtag "haiku". |
| from:interior | sent from Twitter account "interior". |
| to:NASA | a Tweet authored in reply to Twitter account "NASA". |
| @NASA | mentioning Twitter account "NASA". |
| puppy filter:media | containing "puppy" and an image or video. |
| puppy -filter:retweets | containing "puppy", filtering out retweets |
| superhero since:2015-12-21 | containing "superhero" and sent since date "2015-12-21" (year-month-day). |
| puppy until:2015-12-21 | containing "puppy" and sent before the date "2015-12-21". |

Search operators documentation is in [Standard search operators](https://developer.twitter.com/en/docs/tweets/rules-and-filtering/overview/standard-operators).


## Examples

```shell script
$ twitterscraper --query twitter --limit 1000
$ cat tweets.json | jq . | less
```

```json
[
  {
    "screen_name": "@screenname",
    "name": "name",
    "user_id": 1194529546483000000,
    "tweet_id": 1282659891992000000,
    "tweet_url": "https://twitter.com/screenname/status/1282659891992000000",
    "created_at": "2020-07-13 12:00:00 +0000",
    "text": "Thanks Twitter!"
  }
]
```

## CLI Options

| Option | Description | Default |
| ------------- | ------------- | ------------- |
| `-h`, `--help` | This option displays a summary of twitterscraper. | |
| `--query` | Specify a keyword used during the search. | |
| `--start_date` | Set the date from which twitterscraper-ruby should start scraping for your query. | |
| `--end_date` | Set the enddate which twitterscraper-ruby should use to stop scraping for your query. | |
| `--lang` | Retrieve tweets written in a specific language. | |
| `--limit` | Stop scraping when *at least* the number of tweets indicated with --limit is scraped. | 100 |
| `--threads` | Set the number of threads twitterscraper-ruby should initiate while scraping for your query. | 2 |
| `--proxy` | Scrape https://twitter.com/search via proxies. | false |
| `--output` | The name of the output file. | tweets.json |


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ts-3156/twitterscraper-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ts-3156/twitterscraper-ruby/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Code of Conduct

Everyone interacting in the twitterscraper-ruby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ts-3156/twitterscraper-ruby/blob/master/CODE_OF_CONDUCT.md).
