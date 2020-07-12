module Twitterscraper
  module Http

    module_function

    def get(url, headers = {}, proxy = nil, timeout = nil)
      timeout ||= 3

      if proxy
        ip, port = proxy.split(':')
        http_class = Net::HTTP::Proxy(ip, port.to_i)
        Twitterscraper.logger.info("Using proxy #{proxy}")
      else
        http_class = Net::HTTP
      end

      uri = URI.parse(url)
      http = http_class.new(uri.host, uri.port)
      http.use_ssl = true if url.match?(/^https/)
      http.open_timeout = timeout
      http.read_timeout = timeout
      req = Net::HTTP::Get.new(uri)

      headers.each do |key, value|
        req[key] = value
      end

      res = http.start { http.request(req) }
      res.body
    end
  end
end
