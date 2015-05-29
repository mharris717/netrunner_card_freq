require 'spec_helper'

# require 'sinatra'
# require 'mongoid'
# require 'mharris_ext'
# require 'json'
# require 'open-uri'
# load "ext.rb"
# load 'deck.rb'
# load 'card.rb'
# #require "sinatra/json"
# require 'active_model_serializers'

# Mongoid.load!("mongoid.yml", :test)

# module Sinatra
#   module JSON
#     def json(object, options={})
#       serializer = ActiveModel::Serializer.serializer_for(object)
#       if serializer
#         serializer.new(object).to_json
#       else
#         object.to_json(options)
#       end
#     end
#   end
# end

# class CardSerializer < ActiveModel::Serializer
#   attributes :id, :name, :card_type, :faction, :side, :set_name, :image_url, :ndb_url

#   def id
#     object.id.to_s
#   end

#   def image_url
#     object.local_image_url
#   end
# end

# class DeckSerializer < ActiveModel::Serializer
#   embed :ids, embed_in_root: true
#   attributes :id, :side, :faction, :name
#   has_many :cards, key: :cards, embed_key: :id_str

#   def id
#     object.id.to_s
#   end
# end

def make_card
  Card.create! name: rand(100000000).to_s, code: rand(1000000000).to_s
end

def make_deck
  cards = 5.of do
    make_card
  end
  Deck.create! cards: cards, name: rand(100000000).to_s, side: 'Runner', faction: 'Shaper'
end

describe "deck" do
  it 'smoke' do
    2.should == 2
  end

  let(:deck) do
    make_deck
  end

  it 'single deck' do
    serializer = DeckSerializer.new(deck)
    #puts serializer.as_json.inspect
    serializer.as_json['deck'][:cards].first.should == deck.cards.first.id.to_s
    serializer.as_json[:cards].size.should == 5
  end

  it 'list' do
    decks = 2.of { make_deck }
    serializer = ActiveModel::ArraySerializer.new(decks, root: :decks)
    serializer.as_json.tap do |payload|
      #puts payload.inspect
      payload[:decks].size.should == 2
      payload[:decks].first[:id].should == decks.first.id.to_s
      payload[:cards].size.should == 10
    end
  end
end

describe "card breakdown" do
  before do
    Card.delete_all
    Deck.delete_all
    decks
  end

  let(:decks) do
    2.of { make_deck }
  end

  let(:breakdown) do
    CardBreakdown.new(faction: 'Shaper')
  end

  it 'smoke' do
    breakdown.decks.size.should == 2
    breakdown.freq_hash.size.should == 10
  end

  it 'serializer' do
    serializer = CardBreakdownSerializer.new(breakdown)
    serializer.as_json.tap do |payload|
      payload = HashWithIndifferentAccess.new(payload)
      payload[:card_breakdown][:id].should == 'Shaper'
      payload[:card_frequencies].size.should == 10
      payload[:cards].size.should == 10
    end
  end
end

