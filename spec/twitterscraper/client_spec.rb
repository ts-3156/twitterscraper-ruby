RSpec.describe Twitterscraper::Client do
  let(:client) { described_class.new }

  describe '#cache_enabled?' do
    subject { client.cache_enabled? }
    it { is_expected.to be_truthy }
  end

  describe '#proxy_enabled?' do
    subject { client.proxy_enabled? }
    it { is_expected.to be_truthy }
  end
end
