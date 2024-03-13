#!/usr/bin/env ruby
# encding: utf-8

require 'bundler/setup'
require 'cyclopedio/wiki'
require 'cyclopedio/relatedness'
require 'irb'
require 'progress'

include Cyclopedio::Wiki

at_exit do
  Database.instance.open_database(ENV['WIKI_DB'])
  if ENV['WIKI_PATH']
    Page.path = ENV['WIKI_PATH' + '/pages-articles.xml']
  end
  ARGV.clear
  IRB.start
  Database.instance.close_database
end
