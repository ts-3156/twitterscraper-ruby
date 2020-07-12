module Twitterscraper
  module Proxy

    PROXY_URL = 'https://free-proxy-list.net/'

    class RetryExhausted < StandardError
    end

    class Result
      def initialize(items)
        @items = items.shuffle
        @cur_index = 0
      end

      def sample
        if @cur_index >= @items.size
          reload
        end
        @cur_index += 1
        @items[@cur_index - 1]
      end

      def size
        @items.size
      end

      private

      def reload
        @items = Proxy.get_proxies.shuffle
        @cur_index = 0
        Twitterscraper.logger.debug "Reload #{proxies.size} proxies"
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
        ip, port, https = [0, 1, 6].map { |i| cells[i].text.strip }
        next if https == 'no'
        proxies << ip + ':' + port
      end

      Twitterscraper.logger.debug "Fetch #{proxies.size} proxies"
      Result.new(proxies)
    rescue => e
      if (retries -= 1) > 0
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    end
  end
end
