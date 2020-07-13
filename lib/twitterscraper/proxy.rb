module Twitterscraper
  module Proxy

    PROXY_URL = 'https://free-proxy-list.net/'

    class RetryExhausted < StandardError
    end

    class Pool
      def initialize
        @items = Proxy.get_proxies
        @cur_index = 0
      end

      def sample
        if @cur_index >= @items.size
          reload
        end
        @cur_index += 1
        item = @items[@cur_index - 1]
        Twitterscraper.logger.info("Using proxy #{item}")
        item
      end

      def size
        @items.size
      end

      private

      def reload
        @items = Proxy.get_proxies
        @cur_index = 0
      end
    end

    module_function

    def get_proxies(retries = 3)
      response = Twitterscraper::Http.get(PROXY_URL)
      html = Nokogiri::HTML(response)
      table = html.xpath('//table[@id="proxylisttable"]').first

      proxies = []

      table.xpath('tbody/tr').each do |tr|
        cells = tr.xpath('td')
        ip, port, anonymity, https = [0, 1, 4, 6].map { |i| cells[i].text.strip }
        next unless ['elite proxy', 'anonymous'].include?(anonymity)
        next if https == 'no'
        proxies << ip + ':' + port
      end

      Twitterscraper.logger.debug "Fetch #{proxies.size} proxies"
      proxies.shuffle
    rescue => e
      if (retries -= 1) > 0
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    end
  end
end
