module Twitterscraper
  class Type
    def initialize(value)
      @value = value
    end

    def search?
      @value == 'search'
    end

    def user?
      @value == 'user'
    end
  end
end
