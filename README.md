# twitterscraper-ruby

[![Build Status](https://circleci.com/gh/ts-3156/twitterscraper-ruby.svg?style=svg)](https://circleci.com/gh/ts-3156/twitterscraper-ruby)
[![Gem Version](https://badge.fury.io/rb/twitterscraper-ruby.svg)](https://badge.fury.io/rb/twitterscraper-ruby)

A gem to scrape https://twitter.com/search. This gem is inspired by [taspinar/twitterscraper](https://github.com/taspinar/twitterscraper).

Please feel free to ask [@ts_3156](https://twitter.com/ts_3156) if you have any questions.


## Twitter Search API vs. twitterscraper-ruby

#### Twitter Search API

- The number of tweets: 180 - 450 requests/15 minutes (18,000 - 45,000 tweets/15 minutes)
- The time window: the past 7 days

#### twitterscraper-ruby

- The number of tweets: Unlimited
- The time window: from 2006-3-21 to today


## Installation

First install the library:

```shell script
$ gem install twitterscraper-ruby
````
    

## Usage

#### Command-line interface:

Returns a collection of relevant tweets matching a specified query.

```shell script
$ twitterscraper --type search --query KEYWORD --start_date 2020-06-01 --end_date 2020-06-30 --lang ja \
      --limit 100 --threads 10 --output tweets.json
```

Returns a collection of the most recent tweets posted by the user indicated by the screen_name

```shell script
$ twitterscraper --type user --query SCREEN_NAME --limit 100 --output tweets.json
```

#### From Within Ruby:

```ruby
require 'twitterscraper'
client = Twitterscraper::Client.new(cache: true, proxy: true)
```

Returns a collection of relevant tweets matching a specified query.

```ruby
tweets = client.search(KEYWORD, start_date: '2020-06-01', end_date: '2020-06-30', lang: 'ja', limit: 100, threads: 10)
```

Returns a collection of the most recent tweets posted by the user indicated by the screen_name

```ruby
tweets = client.user_timeline(SCREEN_NAME, limit: 100)
```


## Examples

```shell script
$ twitterscraper --query twitter --limit 1000
$ cat tweets.json | jq . | less
```


## Attributes

### Tweet

```ruby
tweets.each do |tweet|
  puts tweet.tweet_id
  puts tweet.text
  puts tweet.tweet_url
  puts tweet.created_at

  attr_names = hash.keys
  hash = tweet.attrs
  json = tweet.to_json
end
```

```json
[
  {
      "screen_name": "@name",
      "name": "Name",
      "user_id": 12340000,
      "profile_image_url": "https://pbs.twimg.com/profile_images/1826000000/0000.png",
      "tweet_id": 1234000000000000,
      "text": "Thanks Twitter!",
      "links": [],
      "hashtags": [],
      "image_urls": [],
      "video_url": null,
      "has_media": null,
      "likes": 10,
      "retweets": 20,
      "replies": 0,
      "is_replied": false,
      "is_reply_to": false,
      "parent_tweet_id": null,
      "reply_to_users": [],
      "tweet_url": "https://twitter.com/name/status/1234000000000000",
      "timestamp": 1594793000,
      "created_at": "2020-07-15 00:00:00 +0000"
    }
]
```

- screen_name
- name
- user_id
- profile_image_url
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


## CLI Options

| Option | Type | Description | Value |
| ------------- | ------------- | ------------- | ------------- |
| `--help`       | string  | This option displays a summary of twitterscraper. | |
| `--type`       | string  | Specify a search type. | search(default) or user |
| `--query`      | string  | Specify a keyword used during the search. | |
| `--start_date` | string  | Used as "since:yyyy-mm-dd for your query. This means "since the date". | |
| `--end_date`   | string  | Used as "until:yyyy-mm-dd for your query. This means "before the date". | |
| `--lang`       | string  | Retrieve tweets written in a specific language. | |
| `--limit`      | integer | Stop scraping when *at least* the number of tweets indicated with --limit is scraped. | 100 |
| `--order`      | string  | Sort a order of the results. | desc(default) or asc |
| `--threads`    | integer | Set the number of threads twitterscraper-ruby should initiate while scraping for your query. | 2 |
| `--threads_granularity` | string | day or hour | auto |
| `--chart_grouping` | string | day, hour or minute | auto |
| `--proxy`      | boolean | Scrape https://twitter.com/search via proxies. | true(default) or false |
| `--cache`      | boolean | Enable caching. | true(default) or false |
| `--format`     | string  | The format of the output. | json(default) or html |
| `--output`     | string  | The name of the output file. | tweets.json |
| `--verbose`    |         | Print debug messages. | |


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ts-3156/twitterscraper-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ts-3156/twitterscraper-ruby/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Code of Conduct

Everyone interacting in the twitterscraper-ruby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ts-3156/twitterscraper-ruby/blob/master/CODE_OF_CONDUCT.md).
