dir = File.expand_path(File.dirname(__FILE__))
load "#{dir}/../core.rb"
require 'active_model_serializers'

ActiveModel::Serializer.setup do |config|
  config.embed = :ids
  config.embed_in_root = true
end

class BaseSerializer < ActiveModel::Serializer
  def id
    object.id.to_s
  end
end

class CardSerializer < BaseSerializer
  attributes :id, :name, :card_type, :faction, :side, :set_name, :image_url, :ndb_url

  def image_url
    object.local_image_url
  end
end

class DeckSerializer < BaseSerializer
  attributes :id, :side, :faction, :name
  has_many :cards, key: :cards, embed_key: :id_str
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

class CardFrequencySerializer < BaseSerializer
  attributes :id, :perc
  has_one :card, key: :card, embed_key: :id_str
end

class CardBreakdownSerializer < BaseSerializer
  attributes :id, :num_decks
  has_many :card_frequencies, key: :cardFrequencies, embed_key: :id_str

  def card_frequencies
    res = []
    object.freq_hash.each_sorted_by_value_desc(10) do |card,num|
      res << CardFrequency.new(card: card, perc: num.to_f / object.decks.size, faction: object.faction)
    end
    res
  end

  def id
    object.faction
  end

  def num_decks
    object.decks.size
  end
end

class CardFrequency
  include FromHash
  include ActiveModel::Serializers::JSON
  attr_accessor :card, :perc, :faction

  def id
    "#{faction}#{card.name}".downcase.gsub(' ','').gsub("-",'')
  end

  def attributes
    {'id' => id, 'card' => card, 'perc' => perc}
  end

  class << self
    # def for(faction)
    #   breakdown = CardBreakdown.new(faction: faction)
    #   res = []
    #   breakdown.freq_hash.each_sorted_by_value_desc(50) do |card,num|
    #     res << CardFrequency.new(card: card, perc: num.to_f / breakdown.decks.size, faction: faction)
    #   end
    #   res
    # end
  end
end