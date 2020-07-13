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

Command line:

```shell script
$ twitterscraper --query KEYWORD --start_date 2020-06-01 --end_date 2020-06-30 --lang ja --limit 100 --threads 10 --proxy --output output.json
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
  puts tweet.created_at
  puts tweet.tweet_url
end
```

### Tweet Attributes

- tweet_id
- text
- user_id
- screen_name
- name
- tweet_url
- created_at


## CLI Options

#### `-h`, `--help`

This option displays a summary of twitterscraper.

#### `--query`

Specify a keyword used during the search.

#### `--start_date`

Set the date from which twitterscraper-ruby should start scraping for your query.

#### `--end_date`

Set the enddate which twitterscraper-ruby should use to stop scraping for your query.

#### `--lang`

Retrieve tweets written in a specific language. 

#### `--limit`

Stop scraping when *at least* the number of tweets indicated with --limit is scraped.

#### `--threads`

Set the number of threads twitterscraper-ruby should initiate while scraping for your query.

#### `--proxy`

Scrape https://twitter.com/search via proxies.

#### `--output`

The name of the output file.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ts-3156/twitterscraper-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ts-3156/twitterscraper-ruby/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Code of Conduct

Everyone interacting in the twitterscraper-ruby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ts-3156/twitterscraper-ruby/blob/master/CODE_OF_CONDUCT.md).
