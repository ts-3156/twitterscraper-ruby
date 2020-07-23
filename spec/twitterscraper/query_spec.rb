RSpec.describe Twitterscraper::Query do
  let(:query) { Class.new { include Twitterscraper::Query }.new }

  describe '#build_queries' do
    subject { query.build_queries('aaa', start_date, end_date, 'day', Twitterscraper::Type.new('search')) }

    context 'start_date and end_date are passed' do
      let(:start_date) { '2020-01-01' }
      let(:end_date) { '2020-01-02' }
      it { is_expected.to eq(['aaa since:2020-01-01_00:00:00_UTC until:2020-01-02_00:00:00_UTC']) }
    end

    context 'only start_date is passed' do
      let(:start_date) { '2020-01-01' }
      let(:end_date) { nil }
      it { is_expected.to eq(['aaa since:2020-01-01_00:00:00_UTC']) }
    end

    context 'only end_date is passed' do
      let(:start_date) { nil }
      let(:end_date) { '2020-01-02' }
      it { is_expected.to eq(['aaa until:2020-01-02_00:00:00_UTC']) }
    end
  end

  describe '#search' do
    subject { query.search('q', start_date: 'sd', end_date: 'ed', lang: 'l', limit: 'l', daily_limit: 'dl', order: 'o', threads: 't', threads_granularity: 'tg') }
    it do
      expect(query).to receive(:query_tweets).
          with('q', type: 'search', start_date: 'sd', end_date: 'ed', lang: 'l', limit: 'l', daily_limit: 'dl', order: 'o', threads: 't', threads_granularity: 'tg')
      subject
    end
  end

  describe '#user_timeline' do
    subject { query.user_timeline('sn', limit: 'l', order: 'o') }
    it do
      expect(query).to receive(:query_tweets).
          with('sn', type: 'user', start_date: nil, end_date: nil, lang: nil, limit: 'l', daily_limit: nil, order: 'o', threads: 1, threads_granularity: nil)
      subject
    end
  end
end
