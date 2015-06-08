module Setup
  class << self
    def make_redis
      if ENV["REDISTOGO_URL"].present?
        uri = URI.parse(ENV["REDISTOGO_URL"])
        Redis.new(:url => uri)
      else
        Redis.current
      end
    end
  end
end