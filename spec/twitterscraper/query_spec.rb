RSpec.describe Twitterscraper::Query do
  let(:query) { Class.new { include Twitterscraper::Query }.new }

  describe '#search' do
    subject { query.search('q', start_date: 'sd', end_date: 'ed', lang: 'l', limit: 'l', daily_limit: 'dl', order: 'o', threads: 't') }
    it do
      expect(query).to receive(:query_tweets).
          with('q', type: 'search', start_date: 'sd', end_date: 'ed', lang: 'l', limit: 'l', daily_limit: 'dl', order: 'o', threads: 't')
      subject
    end
  end

  describe '#user_timeline' do
    subject { query.user_timeline('sn', limit: 'l', order: 'o') }
    it do
      expect(query).to receive(:query_tweets).
          with('sn', type: 'user', start_date: nil, end_date: nil, lang: nil, limit: 'l', daily_limit: nil, order: 'o', threads: 1)
      subject
    end
  end
end
