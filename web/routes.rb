load 'web/core.rb'
require 'sinatra'

Mongoid.load!("mongoid.yml", :development)

helpers do
  # def json_list(root,single_root,objs,serializer=nil)
  #   serializer ||= ActiveModel::Serializer.serializer_for(objs.first)
  #   content_type :json
  #   res = objs.map { |x| serializer.new(x).as_json[single_root.to_s] }
  #   puts res.inspect
  #   {root => res}.to_json
  # end

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

get "/api/cardBreakdowns/:faction" do
  breakdown = CardBreakdown.new(faction: params[:faction])
  json_single breakdown
end