dir = File.expand_path(File.dirname(__FILE__))
load "#{dir}/core.rb"
require 'sinatra'
require 'redis'

Mongoid.load!("mongoid.yml", :development)

Redis.current.flushdb

helpers do
  # def json_list(root,single_root,objs,serializer=nil)
  #   serializer ||= ActiveModel::Serializer.serializer_for(objs.first)
  #   content_type :json
  #   res = objs.map { |x| serializer.new(x).as_json[single_root.to_s] }
  #   puts res.inspect
  #   {root => res}.to_json
  # end

  def redis
    @redis ||= Redis.current
  end

  def json_list(root,single_root,objs,serializer=nil)
    content_type :json
    serializer = ActiveModel::ArraySerializer.new(objs, root: root)
    serializer.to_json
  end

  def json_single(obj,serializer=nil)
    serializer ||= ActiveModel::Serializer.serializer_for(obj)
    content_type :json
    res = serializer.new(obj).as_json
    res.to_json
  end

  def cached_json(key,&b)
    key += "z"
    content_type :json
    existing = redis.get(key)
    if existing
      existing
    else
      ran = yield
      redis.set key, ran
      ran
    end
  end
end

get "/api/cards" do
  json_list :cards, :card, Card.all.order(name: :asc)
end

get "/api/cards/:id" do
  json_single Card.where(id: params[:id]).first
end

get "/api/decks" do
  json_list :decks, :deck, Deck.all.limit(10)
end

get "/api/cardFrequencies" do
  faction = "Shaper"
  freqs = CardFrequency.for(faction)
  puts freqs.inspect
  json_list :cardFrequencies, :card_frequency, freqs, CardFrequencySerializer
end

get "/api/card_breakdowns/:faction" do
  breakdown = CardBreakdown.new(faction: params[:faction], card_faction: params[:card_faction]||'Criminal')
  json_single breakdown
end

get "/api/card_breakdowns" do
  cached_json "card_breakdowns:#{params[:faction]}:#{params[:card_faction]}:#{params[:included_card]}:#{params[:card_type]}" do
    breakdown = CardBreakdown.new(faction: params[:faction], card_faction: params[:card_faction], card_type: params[:card_type])
    if params[:included_card].present?
      breakdown.included_cards << Card.find(params[:included_card])
    end
    json_list :cardBreakdowns, :card_breakdown, [breakdown]
  end
end