RSpec.describe Twitterscraper::Client do
  let(:client) { described_class.new }
  before { allow(Twitterscraper::Proxy::Pool).to receive(:new).and_return(['a', 'b']) }

  describe '#request_headers' do
    subject { client.request_headers }
    it { is_expected.to be_truthy }
  end

  describe '#cache_enabled?' do
    subject { client.cache_enabled? }
    it { is_expected.to be_truthy }
  end

  describe '#proxy_enabled?' do
    subject { client.proxy_enabled? }
    it { is_expected.to be_truthy }
  end

  describe '#proxies' do
    subject { client.proxies }
    it { is_expected.to be_truthy }
  end
end
