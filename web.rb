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

class CardBreakdownSerializer < ActiveModel::Serializer
  attributes :id
end

helpers do
  # include Sinatra::JSON
end

helpers do
  def json_list(root,single_root,objs,serializer=nil)
    serializer ||= ActiveModel::Serializer.serializer_for(objs.first)
    content_type :json
    res = objs.map { |x| serializer.new(x).as_json[single_root.to_s] }
    {root => res}.to_json
  end

  def json_single(root,obj,serializer=nil)
    serializer ||= ActiveModel::Serializer.serializer_for(obj)
    content_type :json
    res = obj.as_json
    {root => res}.to_json
  end
end

get "/api/cards" do
  json_list :cards, :card, Card.all.order(name: :asc)
end

get "/api/cards/:id" do
  json_single :card, Card.find(params[:id])
end

get "/api/decks" do
  json_list :decks, :deck, Deck.all.limit(10)
end