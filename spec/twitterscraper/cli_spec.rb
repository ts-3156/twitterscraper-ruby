RSpec.describe Twitterscraper::Cli do
  let(:cli) { described_class.new }
  describe '#parse_options' do
    subject { cli.parse_options(ARGV) }

    context 'no option is passed' do
      it do
        result = subject
        expect(result['start_date']).to be_falsey
        expect(result['lang']).to eq('')
        expect(result['limit']).to eq(100)
        expect(result['daily_limit']).to be_falsey
        expect(result['threads']).to eq(2)
        expect(result['format']).to eq('json')
        expect(result['output']).to eq('tweets.json')

        expect(result['cache']).to be_truthy
        expect(result['proxy']).to be_truthy
      end
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
end
