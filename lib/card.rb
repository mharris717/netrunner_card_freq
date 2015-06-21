class SaveCards
  fattr(:url) do
    "http://netrunnerdb.com/api/cards"
  end
  fattr(:body) do
    JSON.parse(open(url).read)
  end

  def attrs_for_raw(raw)
    res = raw.with_keys('faction','code','title','type','side','setname','factioncost','text','quantity','imagesrc','url','subtype')

    res['card_type'] = res.delete('type')
    res['sub_card_type'] = res.delete('subtype')
    res['name'] = res.delete('title')
    res['max_quantity'] = res.delete('quantity')
    res['card_text'] = res.delete('text')
    res['influence'] = res.delete('factioncost')
    res['set_name'] = res.delete('setname')
    res['ndb_url'] = res.delete('url')
    res['remote_image_url'] = "http://netrunnerdb.com" + res.delete('imagesrc')

    res
  end
  def create_card!(raw)
    Card.create! attrs_for_raw(raw)
  end
  def save!
    body.each do |raw|
      save_card! raw
    end
  end
  def save_card!(raw)
    exists = Card.where(code: raw['code']).first
    return if exists
    create_card!(raw)
  end
  # def update!
  #   body.each do |raw|
  #     attrs = attrs_for_raw(raw)
  #     existing = Card.first_only(code: raw['code'])
  #     existing.update_attributes! attrs
  #   end
  # end

  def save_images!
    c = Card.count
    Card.all.each_with_index do |card,i|
      puts "Saving image for #{card.name} #{i}/#{c}"
      local = "images/#{card.code}.png"
      if !File.exists?(local)
        File.create local, open(card.remote_image_url).read
      end
    end

    ember = "/code/orig/netrunner_ui"
    ec "cp -r images #{ember}/public"
  end
end

class Card
  include Mongoid::Document
  field :code, type: String
  field :card_type, type: String
  field :sub_card_type, type: String
  field :faction, type: String
  field :name, type: String
  field :side, type: String
  field :set_name, type: String
  field :influence, type: Integer
  field :card_text
  field :max_quantity, type: Integer
  field :remote_image_url
  field :ndb_url

  def local_image_url
    "images/#{code}.png"
  end

  validates :code, presence: true, uniqueness: true

  def name_and_set
    "#{name.rpad(25)} #{set_name.to_s.rpad(20)} #{faction}"
  end
end

class CardBreakdown
  include FromHash
  attr_accessor :faction, :card_faction, :card_type
  fattr(:included_cards) { [] }

  def id
    [faction,card_faction,card_type,included_cards.first.andand.id].join("_")
  end

  fattr(:decks) do
    res = Deck.for_faction(faction)
    if included_cards.size > 0
      codes = included_cards.map { |x| x.code }
      res = res.where("cards.code" => {"$all" => codes})
    end
    res
  end

  def use_card_faction?(card)
    return true if card_faction.blank?
    return true if card_faction == card.faction
    return true if card_faction == 'Splashed' && card.faction != faction && card.faction != 'Neutral'
    return true if card_faction == 'Off Faction' && card.faction != faction
    false
  end

  def use_card_type?(card)
    return true if card_type.blank?
    return true if card_type == card.card_type
    false
  end

  def use_card?(card)
    use_card_faction?(card) && use_card_type?(card)
  end

  fattr(:freq_hash) do
    res = Hash.new { |h,k| h[k] = 0 }
    decks.each do |deck|
      deck.cards.each do |card|
        res[card] += 1 if use_card?(card)
      end
    end
    res
  end

  fattr(:set_hash) do
    res = Hash.new { |h,k| h[k] = 0 }
    decks.each do |deck|
      deck.cards.each do |card|
        res[card.set_name] += 1 if use_card?(card)
      end
    end
    res
  end

  fattr(:set_hashx) do
    res = Hash.new { |h,k| h[k] = 0 }
    freq_hash.each_sorted_by_value_desc(50) do |card,num|
      res[card.set_name] += 1
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

  def print_sets!
    puts faction.to_s.upcase
    set_hash.each_sorted_by_value_desc(20) do |set,num|
      puts "#{num} #{set}"
    end
  end
end