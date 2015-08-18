puts "Decks: #{Deck.count}"

def cluster
  $cluster ||= CardCluster.new(base_card: card)
end

def card
  $card ||= Card.first_only(name: /Noise/)
end

#puts card.inspect

#puts "Generic Decks: #{cluster.generic_breakdown.decks.count}"
#puts "Specific Decks: #{cluster.specific_breakdown.decks.count}"

# Deck.first.cards.each do |card|
#   puts card.name
# end

#puts Deck.where(cards: card).count
#res.where("cards.code" => {"$all" => codes})
#puts Deck.where("cards.code" => {"$all" => [card.code]}).count


cluster.card_comps[0...50].each { |x| puts x }