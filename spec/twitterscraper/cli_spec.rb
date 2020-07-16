RSpec.describe Twitterscraper::Cli do
  let(:cli) { described_class.new }
  describe '#parse_options' do
    subject { cli.parse_options(ARGV) }
    it do
      result = subject
      expect(result['start_date']).to be_falsey
      expect(result['lang']).to eq('')
      expect(result['limit']).to eq(100)
      expect(result['daily_limit']).to be_falsey
      expect(result['threads']).to eq(2)
      expect(result['format']).to eq('json')
      expect(result['output']).to eq('tweets.json')
    end
  end
end
