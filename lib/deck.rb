class SaveDate
  include FromHash
  attr_accessor :date

  fattr(:url) do
    d = date.strftime("%Y-%m-%d")
    "http://netrunnerdb.com/api/decklists/by_date/#{d}"
  end

  fattr(:body) do
    raw = open(url).read
    JSON.parse(raw)
  end

  fattr(:exists) do
    DeckDay.where(date: date).count > 0
  end

  def create!
    DeckDay.create! date: date, decks: body
  end

  def save!
    create! unless exists
  end

  class << self
    def save!(num_days=nil)
      num_days = 50 if num_days.blank?
      date = Date.today - 1
      num_days.times do
        puts "Saving list for #{date}"
        save = SaveDate.new(date: date)
        save.save!
        date -= 1
      end
    end
  end
end

class DeckDay
  include Mongoid::Document

  field :date, type: Date
  field :decks, type: Array

  validates :date, presence: true, uniqueness: true

  def save_decks!
    puts "Saving individual decks for #{date}. Starting count: #{Deck.count}"
    decks.each do |raw|
      SaveDeck.new(raw_deck: raw).save!
    end
  end
end

class SaveDeck
  include FromHash
  attr_accessor :raw_deck

  fattr(:attrs) do
    res = {}
    res[:ndb_id] = ndb_id
    res[:name] = raw_deck['name']
    res[:created_at] = raw_deck['creation']
    res[:description] = raw_deck['description']
    res[:creator] = raw_deck['username']
    res[:cards] = cards
    res[:card_counts] = card_counts
    res[:faction] = faction
    res[:side] = side
    res
  end

  fattr(:cards) do
    res = []
    raw_deck['cards'].each do |code,num|
      res << Card.first_only(code: code)
    end
    res
  end

  fattr(:card_counts) do
    res = {}
    raw_deck['cards'].each do |code,num|
      card = Card.first_only(code: code)
      res[card.name] = num
    end
    res
  end

  fattr(:faction) do
    #cards.group_by { |x| x.faction }.to_a.sort_by { |x| x[1].size }.last[0]
    cards.select { |x| x.card_type == 'Identity' }.first_only.faction
  end

  fattr(:side) do
    cards.first.side
  end

  def ndb_id
    raw_deck['id']
  end

  fattr(:exists) do
    Deck.where(ndb_id: ndb_id).count > 0
  end

  def create!
    # require 'pp'
    # pp attrs
    cards = attrs.delete(:cards)
    res = Deck.new(attrs)
    res.cards = cards
    res.save!
    res
  end

  def save!
    create! unless exists
  end

  def self.save_all!
    DeckDay.order(date: :desc).limit(Setup.num_days).each { |x| x.save_decks! }
  end
end

class Deck
  include Mongoid::Document

  field :ndb_id, type: Integer
  field :name
  field :created_at, type: Time
  field :description
  field :creator
  embeds_many :cards
  field :card_counts, type: Hash

  field :side
  field :faction

  validates :side, presence: true, inclusion: %w(Runner Corp)
  validates :faction, presence: true

  scope(:for_faction, lambda do |faction|
    raise "no faction passed to for_faction" unless faction.present?
    aggs = {}
    aggs['Runner'] = %w(Anarch Shaper Criminal)
    aggs['Corp'] = ['NBN']

    puts "for_faction #{faction}"
    if aggs[faction.to_s]
      where(side: faction)
    else
      where(faction: faction)
    end
  end)

  def update_cards!
    res = []

    cards.each do |card|
      res << Card.first_only(code: card.code)
    end

    update_attributes! cards: res
  end
end