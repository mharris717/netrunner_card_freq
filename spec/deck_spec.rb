require 'spec_helper'

describe Deck do
  it 'for_faction' do
    Deck.delete_all
    deck1 = make_deck faction: 'Shaper', side: 'Runner'
    deck2 = make_deck faction: 'Anarch', side: 'Runner'
    deck3 = make_deck faction: 'NBN', side: 'Corp'

    Deck.for_faction('Shaper').should == [deck1]
    Deck.for_faction('Runner').should == [deck1,deck2]
  end
end