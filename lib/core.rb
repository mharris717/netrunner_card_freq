require 'mongoid'
require 'mharris_ext'
require 'json'
require 'open-uri'

dir = File.expand_path(File.dirname(__FILE__))
load "#{dir}/ext.rb"
load "#{dir}/deck.rb"
load "#{dir}/card.rb"