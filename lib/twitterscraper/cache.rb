require 'base64'
require 'digest/md5'

module Twitterscraper
  class Cache
    def initialize()
      @ttl = 3600 # 1 hour
      @dir = 'cache'
      Dir.mkdir(@dir) unless File.exist?(@dir)
    end

    def read(key)
      key = cache_key(key)
      file = File.join(@dir, key)
      entry = Entry.from_json(File.read(file))
      entry.value if entry.time > Time.now - @ttl
    rescue Errno::ENOENT => e
      nil
    end

    def write(key, value)
      key = cache_key(key)
      entry = Entry.new(key, value, Time.now)
      file = File.join(@dir, key)
      File.write(file, entry.to_json)
    end

    def fetch(key, &block)
      if (value = read(key))
        value
      else
        yield.tap { |v| write(key, v) }
      end
    end

    def cache_key(key)
      value = key.gsub(':', '%3A').gsub('/', '%2F').gsub('?', '%3F').gsub('=', '%3D').gsub('&', '%26')
      value = Digest::MD5.hexdigest(value) if value.length >= 100
      value
    end

    class Entry < Hash
      attr_reader :key, :value, :time

      def initialize(key, value, time)
        @key = key
        @value = value
        @time = time
      end

      def attrs
        {key: @key, value: @value, time: @time}
      end

      def to_json
        hash = attrs
        hash[:value] = Base64.encode64(hash[:value])
        hash.to_json
      end

      class << self
        def from_json(text)
          json = JSON.parse(text)
          new(json['key'], Base64.decode64(json['value']), Time.parse(json['time']))
        end
      end
    end
  end
end
