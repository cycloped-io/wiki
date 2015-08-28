#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'slop'
require 'cyclopedio/wiki'
require 'progress'
require 'csv'
include Cyclopedio::Wiki

options = Slop.new do
  banner "Usage: #{$PROGRAM_NAME} -d path/to/rod -i infoboxes.csv\n" +
    "Load article infobox inclusion data to ROD"

  on :d=, :database, 'ROD Database path', required: true
  on :i=, :input, 'File with infoboxes', required: true
end
begin
  options.parse
rescue Slop::MissingOptionError => ex
  puts ex
  puts options
  exit
end

total = 0
linked = 0
Database.instance.open_database(options[:database],readonly: false)
at_exit do
  Database.instance.close_database
end
CSV.open(options[:input],"r:utf-8") do |input|
  input.with_progress do |article_id,infoboxes|
    begin
      article = Article.find_by_wiki_id(article_id.to_i)
      next if article.nil?
      total += 1
      infoboxes = infoboxes.map do |infobox|
        infobox.sub(/infobox/i,"").strip
      end.reject{|i| i.empty? || i =~ /\// }
      next if infoboxes.empty?
      article.infoboxes = infoboxes
      article.store
      linked += 1
    rescue Interrupt
      puts
      break
    rescue Exception => ex
      puts "error #{article_id}:#{infoboxes}"
      puts ex
      puts ex.backtrace[5]
    end
  end
end
puts "Linked articles: #{linked}/#{total}"
