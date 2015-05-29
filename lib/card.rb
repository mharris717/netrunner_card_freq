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
  def create!
    body.each do |raw|
      create_card! raw
    end
  end
  def save!
    create! if Card.count == 0
  end
  def update!
    body.each do |raw|
      attrs = attrs_for_raw(raw)
      existing = Card.first_only(code: raw['code'])
      existing.update_attributes! attrs
    end
  end

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