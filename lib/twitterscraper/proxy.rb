module Twitterscraper
  module Proxy

    PROXY_URL = 'https://free-proxy-list.net/'

    class RetryExhausted < StandardError
    end

    module_function

    def get_proxies(retries = 3)
      response = Twitterscraper::Http.get(PROXY_URL)
      html = Nokogiri::HTML(response)
      table = html.xpath('//*[@id="proxylisttable"]').first

      proxies = []

      table.xpath('tbody/tr').each do |tr|
        cells = tr.xpath('td')
        ip, port = cells[0].text.strip, cells[1].text.strip
        proxies << ip + ':' + port
      end

      proxies
    rescue => e
      if (retries -= 1) > 0
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    end
  end
end
