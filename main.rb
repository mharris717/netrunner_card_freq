require 'mongoid'
require 'mharris_ext'
require 'json'
require 'open-uri'
load "ext.rb"
load 'deck.rb'
load 'card.rb'

Mongoid.load!("mongoid.yml", :development)

class CardBreakdown
  include FromHash
  attr_accessor :faction

  fattr(:decks) do
    Deck.where(faction: faction)
  end

  fattr(:freq_hash) do
    res = Hash.new { |h,k| h[k] = 0 }
    decks.each do |deck|
      deck.cards.each do |card|
        res[card] += 1
      end
    end
    res
  end

  def print!
    puts faction.to_s.upcase
    freq_hash.each_sorted_by_value_desc(10) do |card,num|
      perc = num.to_f / decks.size.to_f
      if perc > 0.05
        puts "#{perc.to_s_perc} #{card.name_and_set}"
      end
    end
  end
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

# puts Card.all.map { |x| x.card_type }.uniq.sort.inspect
# puts Card.all.map { |x| x.faction }.uniq.sort.inspect

# Card.delete_all
# SaveCards.new.save!
# SaveCards.new.save_images!

# puts DeckDay.count

# Card.delete_all
# Deck.delete_all
# SaveCards.new.save!
# SaveDeck.save_all!
# puts Card.count

#SaveCards.new.update!
#Deck.all.each { |x| x.update_cards! }

def print_counts
  puts "COUNTS"
  puts "Card: #{Card.count}"
  puts "Deck: #{Deck.count}"
end

# print_counts

# %w(Anarch Shaper Criminal).each do |faction|
#   breakdown = CardBreakdown.new(faction: faction)
#   breakdown.print!
#   puts "\n"
# end

# Card.delete_all
# SaveCards.new.save!

#Deck.delete_all
#SaveDeck.save_all!

#print_counts

#counts.print!

# def deck_faction(deck)

# end

# deck = DeckDay.first.decks.first
# deck['cards'].each do |code,num|
#   card = Card.first_only(code: code)
#   puts card.faction
# end

#puts DeckDay.first.deck_objs.first.faction
