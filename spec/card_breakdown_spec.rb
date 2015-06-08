require 'spec_helper'

describe 'card breakdown' do
  before do
    Deck.delete_all
    Card.delete_all
  end

  it 'smoke' do
    cards1 = 2.of { make_card faction: 'Anarch' }
    cards2 = 2.of { make_card faction: 'Anarch' }
    decks = 2.of { make_deck faction: 'Anarch', cards: cards1 } + 
            1.of { make_deck faction: 'Anarch', cards: cards2 } + 
            1.of { make_deck faction: 'Shaper' }

    breakdown = CardBreakdown.new(faction: 'Anarch')
    breakdown.decks.size.should == 3
    breakdown.freq_hash.size.should == 4
    breakdown.freq_hash[cards1.first].should == 2
  end

  it 'card_faction' do
    cards = 2.of { make_card faction: 'Anarch' } + 1.of { make_card faction: 'Shaper' }
    decks = 2.of { make_deck faction: 'Anarch', cards: cards } 

    breakdown = CardBreakdown.new(faction: 'Anarch', card_faction: 'Anarch')
    breakdown.freq_hash.size.should == 2

    breakdown = CardBreakdown.new(faction: 'Anarch', card_faction: 'Splashed')
    breakdown.freq_hash.size.should == 1
  end

  it 'included cards' do
    cards1 = 2.of { make_card faction: 'Anarch' }
    cards2 = 2.of { make_card faction: 'Anarch' }
    decks = 2.of { make_deck faction: 'Anarch', cards: cards1 } + 
            1.of { make_deck faction: 'Anarch', cards: cards2 } + 
            1.of { make_deck faction: 'Shaper' }

    breakdown = CardBreakdown.new(faction: 'Anarch', included_cards: [cards1.first])
    breakdown.decks.size.should == 2

  end
end