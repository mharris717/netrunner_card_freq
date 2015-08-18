def env
  if File.exist?("/code/orig/netrunner_ui")
    :development
  else
    :production
  end
end

task :environment do
  dir = File.expand_path(File.dirname(__FILE__))
  load "#{dir}/lib/core.rb"

  Mongoid.load!("mongoid.yml", env)
end

task reload_cards: :environment do
  puts "Beginning Card Count: #{Card.count}"
  Card.delete_all
  SaveCards.new.save!
  puts "Ending Card Count: #{Card.count}"
end

task reload_decks: :environment do
  SaveDate.save! Setup.num_days

  Deck.delete_all
  SaveDeck.save_all!
end

task load_new_decks: :environment do
  SaveCards.new.save!
  SaveDate.save!
  SaveDeck.save_all!
end

task load_new_cards: :environment do
  puts Card.count
  SaveCards.new.save!
  puts Card.count
end

task refresh_all: %w(reload_cards reload_decks)

task clear_last_modified: :environment do
  redis = Setup.make_redis
  redis.del :global_last_modified
end

task reduce_last_modified: :environment do
  redis = Setup.make_redis
  val = redis.get :global_last_modified
  val = val - 60*60*24
  res.set :global_last_modified, val
end