task :load_cards do
  dir = File.expand_path(File.dirname(__FILE__))
  load "#{dir}/lib/core.rb"

  Mongoid.load!("mongoid.yml", :production)

  puts "Beginning Card Count: #{Card.count}"
  Card.delete_all
  SaveCards.new.save!
  puts "Ending Card Count: #{Card.count}"
end

task :load_decks do
  dir = File.expand_path(File.dirname(__FILE__))
  load "#{dir}/lib/core.rb"

  Mongoid.load!("mongoid.yml", :production)
  
  SaveDate.save!

  Deck.delete_all
  SaveDeck.save_all!
end