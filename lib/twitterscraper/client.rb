module Twitterscraper
  class Client
    include Query

    USER_AGENT_LIST = [
        'Mozilla/5.0 (Windows; U; Windows NT 6.1; x64; fr; rv:1.9.2.13) Gecko/20101203 Firebird/3.6.13',
        'Mozilla/5.0 (compatible, MSIE 11, Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko',
        'Mozilla/5.0 (Windows; U; Windows NT 6.1; rv:2.2) Gecko/20110201',
        'Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16',
        'Mozilla/5.0 (Windows NT 5.2; RW; rv:7.0a1) Gecko/20091211 SeaMonkey/9.23a1pre',
    ]

    def initialize(cache: true, proxy: true)
      @request_headers = {'User-Agent': USER_AGENT_LIST.sample, 'X-Requested-With': 'XMLHttpRequest'}
      Twitterscraper.logger.info "Headers #{@request_headers}"

      @cache = cache

      if (@proxy = proxy)
        @proxies = Proxy::Pool.new
        Twitterscraper.logger.debug "Fetch #{@proxies.size} proxies"
      else
        @proxies = []
        Twitterscraper.logger.debug 'Proxy disabled'
      end
    end

    def request_headers
      @request_headers
    end

    def cache_enabled?
      @cache
    end

    def proxy_enabled?
      @proxy
    end

    def proxies
      @proxies
    end
  end
end
