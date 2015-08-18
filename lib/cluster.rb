class CardCluster
  include FromHash
  attr_accessor :base_card

  fattr(:generic_breakdown) do
    CardBreakdown.new(faction: base_card.faction)
  end

  fattr(:specific_breakdown) do
    CardBreakdown.new(faction: base_card.faction, included_cards: [base_card])
  end

  def make_comp(card)
    generic_perc = get_perc(generic_breakdown,card)
    specific_perc = get_perc(specific_breakdown,card)
    generic_count = generic_breakdown.freq_hash[card] || 0
    specific_count = specific_breakdown.freq_hash[card] || 0
    CardComp.new(card: card, 
                 generic_perc: generic_perc, 
                 specific_perc: specific_perc, 
                 generic_count: generic_count,
                 specific_count: specific_count)
  end

  def get_perc(breakdown,card)
    num = breakdown.freq_hash[card] || 0
    decks = breakdown.decks.count.to_f
    raise "no decks" unless decks > 0
    num.to_f / decks
  end

  fattr(:all_cards) do
    res = generic_breakdown.freq_hash.keys + specific_breakdown.freq_hash.keys
    res.uniq
  end

  fattr(:card_comps) do
    all_cards.map do |card|
      make_comp(card)
    end.sort.reverse
  end
end

class CardComp
  include FromHash
  attr_accessor :card, :generic_perc, :specific_perc, :generic_count, :specific_count

  fattr(:specific_factor) do
    res = if generic_perc == 0
      10
    else
      specific_perc / generic_perc
    end
    res.to_f**2 * specific_count.to_f
  end

  def <=>(comp)
    puts "<=> #{specific_factor}"
    specific_factor.to_f <=> comp.specific_factor.to_f
  end

  def to_s
    "#{card.name} #{specific_perc.to_s_perc} (#{specific_count}) / #{generic_perc.to_s_perc} (#{generic_count})"
  end
end