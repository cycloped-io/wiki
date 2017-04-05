#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'slop'
require 'cyclopedio/wiki'
require 'csv'
require 'progress'
require 'set'
include Cyclopedio::Wiki

options = Slop.new do
  banner 'Usage: links.rb -d db_path -w data_path -r direction'

  on 'd', 'db_path', 'Database path', argument: :mandatory, required: true
  on 'w', 'data_path', 'WikiMiner files path', argument: :mandatory, required: true
  on 'r', 'direction', 'Links direction', argument: :mandatory, required: true
end
begin
  options.parse
rescue Slop::MissingOptionError
  puts options
  exit
end

db_path = options[:db_path]
data_path = options[:data_path]
direction = options[:direction]


csv = CSV

errors = File.open("log/missing_pagelink.log","w")
total = 0
linked = 0

if direction == "in"
  file_name = "linkByTarget"
  method_name = :linking_articles
else
  file_name = "linkBySource"
  method_name = :linked_articles
end

Database.instance.open_database(db_path, :readonly => false)
open("#{data_path}/#{file_name}.csv","r:utf-8") do |file|
  file.with_progress.each_with_index do |line,index|
    begin
      if direction == "in"
        article_identifier, *related_elements = csv.parse(line).first
        article = Article.find_by_name(article_identifier)
        related_elements.map! do |element_id|
          total += 1
          [element_id, Article.find_by_wiki_id(element_id.to_i)]
        end
      else
        article_identifier, *related_elements = csv.parse(line).first
        article = Article.find_by_wiki_id(article_identifier.to_i)
        related_elements.map! do |element_name|
          total += 1
          [element_name, Article.find_by_name(element_name)]
        end
      end
      if article.nil?
        errors.puts "Missing subject: #{article_identifier}"
        next
      end
      related_elements.reject{ |_, e| e.nil? }.sort_by{ |_, e| e.rod_id }.
	  each do |element_identifier, element|
        article.send(method_name) << element
        linked += 1
      end
      article.store
      article = nil
    rescue Exception => ex
      puts line
      puts ex
      puts ex.backtrace
    end
  end
end
errors.close
Database.instance.close_database

puts "Linked articles (#{options[:direction]}) #{linked}/#{total}"
