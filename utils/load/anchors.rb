#!/usr/bin/env ruby
# encoding: utf-8

# This script loads the the anchors and their occurrences to the database.
# The back-link (from concept to occurrence) is created in the occurrences.rb
# script.

require 'bundler/setup'
require 'slop'
require 'cyclopedio/wiki'
require 'csv'
require 'progress'
require 'set'
include Cyclopedio::Wiki

opts = Slop.new do
  banner 'Usage: init.rb -d db_path -w data_path'

  on 'd', 'db_path', 'Database path', argument: :mandatory, required: true
  on 'w', 'data_path', 'CSV files extracted from SQL', argument: :mandatory, required: true
end
begin
  opts.parse
rescue Slop::MissingOptionError
  puts opts
  exit
end

db_path = opts[:db_path]
data_path = opts[:data_path]

Database.instance.open_database(db_path, :readonly => false)

FileUtils.mkdir_p("log") unless File.exist?("log")
missing_pages = File.open("log/missing_anchor_pages.log","w")
total = 0
anchor_count = 0
occurrence_count = 0
csv = CSV
Progress.start("Loading anchors", `wc -l #{data_path}/anchors.csv`.to_i)
open("#{data_path}/anchors.csv","r:utf-8") do |file|
  file.each.with_index do |line,index|
    #puts "#{index} #{Time.now}" if index % 10000 == 0
    begin
      Progress.step(1)
      total += 1
      tuple = csv.parse(line)
      link, linked_count, unlinked_count, *occurrences = tuple[0]
      anchor = Anchor.find_by_value(link)
      if anchor.nil?
        anchor = Anchor.new(value: link, linked_count: linked_count.to_i, unlinked_count: unlinked_count.to_i)
      end
      next unless anchor.valid?
      anchor_count += 1
      occurrences.each_slice(2) do |wiki_id, count|
        wiki_id = wiki_id.to_i
        count = count.to_i
        next if count == 0
        concept = Article.find_with_redirect_id(wiki_id)
        if concept.nil?
          missing_pages.puts wiki_id.to_s
          next
        end
        occurrence = Occurrence.new(article: concept, anchor: anchor, count: count)
        occurrence.store
        #concept.occurrences << occurrence
        anchor.occurrences << occurrence
      end
      anchor.store(false)
    rescue Interrupt
      break
    rescue Exception => ex
      puts line
      puts ex
      break
    end
  end
end
Progress.stop
Database.instance.close_database
missing_pages.close
puts "Anchors #{anchor_count}/#{total}"
Database.instance.open_database(db_path)
puts Anchor.find_by_value("Gierałtowice").occurrences.to_a[..10].map{|a| "- #{a}" }.join("\n")
Database.instance.close_database
