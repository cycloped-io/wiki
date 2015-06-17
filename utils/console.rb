#!/usr/bin/env ruby
# encding: utf-8

require 'bundler/setup'
require 'cyclopedio/wiki'
require 'irb'
require 'progress'

include Cyclopedio::Wiki

at_exit do
  Database.instance.open_database(ARGV[0])
  if ENV['WIKI_PATH']
    Page.path = ENV['WIKI_PATH' + '/pages-articles.xml']
  end
  ARGV.clear
  IRB.start
  Database.instance.close_database
end
