dir = File.expand_path(File.dirname(__FILE__))
load "#{dir}/core.rb"
require 'sinatra'

def mongo_env
  if FileTest.exist?("/code/orig/netrunner_decks")
    :development
  else
    :production
  end
end
Mongoid.load!("mongoid.yml", mongo_env)

# Redis.current.flushdb

# helpers do
#   def global_cache_key
#     ENV['global_cache_key'] || "nokey"
#   end

#   def cached_json(key,&b)
#     # key = "#{global_cache_key}:#{key}:#{rand(1000000000000)}"
#     # content_type :json
#     # ignore_existing = (ENV['use_cached_json'] != '1')
#     # redis_get_cached(key, ignore_existing: ignore_existing, &b)
#     yield
#   end
# end

helpers do
  def global_last_modified
    redis_get_cached :global_last_modified do
      Time.now
    end
  end
end

helpers do
  # def json_list(root,single_root,objs,serializer=nil)
  #   serializer ||= ActiveModel::Serializer.serializer_for(objs.first)
  #   content_type :json
  #   res = objs.map { |x| serializer.new(x).as_json[single_root.to_s] }
  #   puts res.inspect
  #   {root => res}.to_json
  # end

  def redis
    @redis ||= Setup.make_redis
  end

  def redis_get_cached(key,ops={},&b)
    existing = redis.get(key)
    if existing && !ops[:ignore_existing]
      existing
    else
      res = yield
      redis.set key, res
      res
    end
  end

  def json_list(root,single_root,objs,serializer=nil)
    content_type :json
    serializer = ActiveModel::ArraySerializer.new(objs, root: root)
    res = serializer.as_json
    res[:meta] = {generated_at: Time.now, global_last_modified: global_last_modified}
    res.to_json
  end

  def json_single(obj,serializer=nil)
    serializer ||= ActiveModel::Serializer.serializer_for(obj)
    content_type :json
    res = serializer.new(obj).as_json
    res[:meta] = {generated_at: Time.now}
    res.to_json
  end

  def bootstrap_index(index_key)
    index_key &&= "netrunner-ui:#{index_key}"
    index_key ||= redis.get("netrunner-ui:current")
    redis.get(index_key)
  end
end

get "/api/cards" do
  etag "all_cards"
  last_modified global_last_modified
  json_list :cards, :card, Card.all.order(name: :asc)
end

get "/api/cards/:id" do
  etag "card_#{params[:id]}"
  last_modified global_last_modified
  json_single Card.where(id: params[:id]).first
end

# get "/api/decks" do
#   json_list :decks, :deck, Deck.all.limit(10)
# end

# get "/api/cardFrequencies" do
#   faction = "Shaper"
#   freqs = CardFrequency.for(faction)
#   puts freqs.inspect
#   json_list :cardFrequencies, :card_frequency, freqs, CardFrequencySerializer
# end

# get "/api/card_breakdowns/:faction" do
#   breakdown = CardBreakdown.new(faction: params[:faction], card_faction: params[:card_faction]||'Criminal')
#   json_single breakdown
# end

get "/api/card_breakdowns" do
  redis.incr :breakdown_visits
  breakdown = CardBreakdown.new(faction: params[:faction], 
                                card_faction: params[:card_faction], 
                                card_type: params[:card_type])
  if params[:included_card].present?
    breakdown.included_cards << Card.find(params[:included_card])
  end
  puts "before etag"
  etag "card_breakdown_#{breakdown.id}"
  last_modified global_last_modified
  puts "after etag"
  res = json_list :cardBreakdowns, :card_breakdown, [breakdown]
  puts "after full render"
  res
end

get '/' do
  redis.incr :index_visits
  etag "ember_index"
  last_modified global_last_modified
  content_type 'text/html'
  bootstrap_index(params[:index_key])
end

get "/visit_counts" do
  index = redis.get(:index_visits)
  breakdown = redis.get(:breakdown_visits)
  "Index: #{index}, Breakdown: #{breakdown}"
end