require 'sinatra'
require 'mongoid'
require 'mharris_ext'
require 'json'
require 'open-uri'
load "ext.rb"
load 'deck.rb'
load 'card.rb'
#require "sinatra/json"
require 'active_model_serializers'

Mongoid.load!("mongoid.yml", :development)

module Sinatra
  module JSON
    def json(object, options={})
      serializer = ActiveModel::Serializer.serializer_for(object)
      if serializer
        serializer.new(object).to_json
      else
        object.to_json(options)
      end
    end
  end
end

class CardSerializer < ActiveModel::Serializer
  attributes :id, :name, :card_type, :faction, :side, :set_name, :image_url, :ndb_url

  def id
    object.id.to_s
  end

  def image_url
    object.local_image_url
  end
end

class DeckSerializer < ActiveModel::Serializer
  attributes :id, :side, :faction, :name, :cards
  #has_many :cards

  def id
    object.id.to_s
  end

  def cards
    object.cards.map { |x| x.id.to_s }
  end
end

# class CardBreakdownSerializer < ActiveModel::Serializer
#   attributes :card_hash

#   def card_hash
#     freq = 
#     res = {}
#     object.freq_hash.each_sorted_by_value_desc(25) do |card,num|
#       res[card.id.to_s]
#     end
#     res
#   end
# end

class CardFrequencySerializer < ActiveModel::Serializer
  attributes :id, :cardName, :perc, :card

  def card
    object.card.id.to_s
  end

  def cardName
    object.card.name
  end
end

class CardFrequency
  include FromHash
  include ActiveModel::Serializers::JSON
  attr_accessor :card, :perc, :faction


  def id
    "#{faction}-#{card.name}"
  end

  def attributes
    {'id' => id, 'card' => card, 'perc' => perc}
  end

  class << self
    def for(faction)
      breakdown = CardBreakdown.new(faction: faction)
      res = []
      breakdown.freq_hash.each_sorted_by_value_desc(50) do |card,num|
        res << CardFrequency.new(card: card, perc: num.to_f / breakdown.decks.size, faction: faction)
      end
      res
    end
  end
end

helpers do
  # include Sinatra::JSON
end

helpers do
  def json_list(root,single_root,objs,serializer=nil)
    serializer ||= ActiveModel::Serializer.serializer_for(objs.first)
    content_type :json
    res = objs.map { |x| serializer.new(x).as_json[single_root.to_s] }
    puts res.inspect
    {root => res}.to_json
  end

  def json_single(root,obj,serializer=nil)
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
  json_single :card, Card.where(id: params[:id]).first
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