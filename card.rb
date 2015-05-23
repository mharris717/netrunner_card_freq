class SaveCards
  fattr(:url) do
    "http://netrunnerdb.com/api/cards"
  end
  fattr(:body) do
    JSON.parse(open(url).read)
  end

  def attrs_for_raw(raw)
    res = raw.with_keys('faction','code','title','type','side','setname','factioncost','text','quantity')

    res['card_type'] = res.delete('type')
    res['name'] = res.delete('title')
    res['max_quantity'] = res.delete('quantity')
    res['card_text'] = res.delete('text')
    res['influence'] = res.delete('factioncost')
    res['set_name'] = res.delete('setname')

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
end

class Card
  include Mongoid::Document
  field :code, type: String
  field :card_type, type: String
  field :faction, type: String
  field :name, type: String
  field :side, type: String
  field :set_name, type: String
  field :influence, type: Integer
  field :card_text
  field :max_quantity, type: Integer

  validates :code, presence: true, uniqueness: true

  def name_and_set
    "#{name.rpad(25)} #{set_name.to_s.rpad(20)} #{faction}"
  end
end