#!/usr/bin/env ruby
# encoding: utf-8

# This script matches the occurrences with concepts.
#
# This is not done in the anchor script, since we would
# have to keep a set of modified concepts which would be
# very large.

require 'bundler/setup'
require 'cyclopedio/wiki'
require 'csv'
require 'progress'
require 'set'
require 'slop'
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
missing_pages = File.open("log/missing_occurrence_pages.log","w")
total = 0
occurrence_count = 0
csv = CSV
Progress.start("Loading occurrences", `wc -l #{data_path}/occurrences.csv`.to_i)
open("#{data_path}/occurrences.csv","r:utf-8") do |file|
  file.each.with_index do |line,index|
    #puts "#{index} #{Time.now}" if index % 10000 == 0
    begin
      Progress.step(1)
      wiki_id, *occurrences = csv.parse(line)[0]
      concept = Article.find_by_wiki_id(wiki_id.to_i)
      next if concept.nil?
      occurrences.each do |link|
        total += 1
        anchor = Anchor.find_by_value(link)
        next if anchor.nil?
        occurrence = anchor.occurrences.find{|o| o.article == concept }
        next if occurrences.nil?
        concept.occurrences << occurrence
        occurrence_count += 1
      end
      concept.store
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

puts "Occurrences #{occurrence_count}/#{total}"
Database.instance.open_database(db_path)
Article.find_by_rod_id(1).occurrences.to_a[..10].map{|a| "- #{a.anchor.value} #{a.count}" }.join("\n")
Database.instance.close_database
