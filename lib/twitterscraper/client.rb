module Twitterscraper
  class Client
    include Query

    def initialize(cache: true, proxy: true)
      @cache = cache
      @proxy = proxy
    end

    def cache_enabled?
      @cache
    end

    def proxy_enabled?
      @proxy
    end
  end
end
