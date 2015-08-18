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

    fattr(:num_days) do
      (ENV['num_days'] || 50).to_i
    end
  end
end