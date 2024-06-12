#!/usr/bin/env ruby
# encding: utf-8

require 'bundler/setup'
require 'cyclopedio/wiki'
require 'cyclopedio/relatedness'
require 'irb'
require 'progress'

include Cyclopedio::Wiki

if ARGV.size == 0
  if ENV['WIKI_DB']
    path = ENV['WIKI_DB']
  else
    puts "You need to set the path to the database, via WIKI_DB or argument to the script"
    exit(1)
  end
else
  path = ARGV[0]
end

at_exit do
  Database.instance.open_database(path)
  if ENV['WIKI_DATA']
    puts ENV['WIKI_DATA']
    Page.path = ENV['WIKI_DATA' + '/pages-articles.xml']
  end
  ARGV.clear
  IRB.start
  Database.instance.close_database
end
