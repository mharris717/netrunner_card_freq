require 'mongoid'
require 'mharris_ext'
require 'json'
require 'open-uri'
load "ext.rb"

Mongoid.load!("mongoid.yml", :development)

class SaveCards
  fattr(:url) do
    "http://netrunnerdb.com/api/cards/"
  end
  fattr(:body) do
    JSON.parse(open(url).read)
  end
  def create!
    body.each do |raw|
      Card.create! raw.with_keys('faction','code','title','type','side','setname')
    end
  end
  def save!
    create! if Card.count == 0
  end
end

class Card
  include Mongoid::Document
  field :code, type: String
  field :type, type: String
  field :faction, type: String
  field :title, type: String
  field :side, type: String
  field :setname, type: String

  validates :code, presence: true, uniqueness: true

  def name_and_set
    s = "(#{setname})".rpad(25)
    "#{title.rpad(25)} #{s} #{faction}"
  end
end

class CardNames
  fattr(:names) { {} }
end

class CardCounts
  fattr(:counts) do
    res = Hash.new { |h,k| h[k] = 0 }
    DeckDay.all.each do |day|
      day.decks.each do |deck|
        deck['cards'].each do |code,num|
          res[code] += 1
        end
      end
    end
    res
  end

  def print!
    counts.each_sorted_by_value_desc do |code,num_decks|
      card = Card.first_only(code: code)
      name = card.name_and_set
      puts "#{num_decks.to_s.lpad(5)} #{name}" if card.side == 'Runner'
    end
  end
end

def counts
  $counts ||= CardCounts.new
end

# puts DeckDay.count

# SaveCards.new.save!
# puts Card.count

#Card.delete_all
SaveCards.new.save!

#counts.print!

# def deck_faction(deck)

# end

# deck = DeckDay.first.decks.first
# deck['cards'].each do |code,num|
#   card = Card.first_only(code: code)
#   puts card.faction
# end

puts DeckDay.first.deck_objs.first.faction
