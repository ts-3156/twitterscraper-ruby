RSpec.describe Twitterscraper::Cli do
  let(:cli) { described_class.new }

  describe '#parse_options' do
    subject { cli.parse_options(ARGV) }

    context 'no option is passed' do
      it do
        result = subject
        expect(result['start_date']).to be_falsey
        expect(result['end_date']).to be_falsey
        expect(result['lang']).to eq('')
        expect(result['limit']).to eq(100)
        expect(result['daily_limit']).to be_falsey
        expect(result['threads']).to eq(10)
        expect(result['threads_granularity']).to eq('auto')
        expect(result['format']).to eq('json')

        expect(result['cache']).to be_truthy
        expect(result['proxy']).to be_truthy
      end
    end

    context '--start_date "2020-01-01" is specified' do
      before { ARGV.concat(['--start_date', '2020-01-01']) }
      it { expect(subject['start_date']).to eq('2020-01-01') }
    end

    context '--end_date "2020-01-02" is specified' do
      before { ARGV.concat(['--end_date', '2020-01-02']) }
      it { expect(subject['end_date']).to eq('2020-01-02') }
    end

    context '--cache false is specified' do
      before { ARGV.concat(['--cache', 'false']) }
      it { expect(subject['cache']).to be_falsey }
    end

    context '--proxy false is specified' do
      before { ARGV.concat(['--proxy', 'false']) }
      it { expect(subject['proxy']).to be_falsey }
    end
  end

  describe '#build_output_name' do
    let(:options) { {'type' => 'search', 'query' => 'q', 'start_date' => 'sd', 'end_date' => 'ed'} }
    subject { cli.build_output_name('f', options) }
    it { is_expected.to eq('out/search_tweets_sd_ed_q.f') }
  end
end
