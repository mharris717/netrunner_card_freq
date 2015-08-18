require 'mongoid'
require 'mharris_ext'
require 'json'
require 'open-uri'
require 'redis'
require 'andand'

dir = File.expand_path(File.dirname(__FILE__))
load "#{dir}/setup.rb"
load "#{dir}/ext.rb"
load "#{dir}/deck.rb"
load "#{dir}/card.rb"
load "#{dir}/cluster.rb"