module Twitterscraper
  class Client
    include Query

    def initialize(cache:)
      @cache = cache
    end

    def cache_enabled?
      @cache
    end
  end
end
