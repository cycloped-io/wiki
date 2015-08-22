#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'slop'
require 'cyclopedio/wiki'
require 'progress'
require 'csv'
require 'set'
include Cyclopedio::Wiki

options = Slop.new do
  banner "Usage: #{$PROGRAM_NAME} -d db_path -w data_path\nMark administrative categories."

  on :d=, 'db_path', 'ROD database path', required: true
  on :t=, 'templates', 'File with ids of categories including the administrative template', required: true
  on :w=, 'data_path', 'Directory with administrative category name patterns (default: data/categories)', default: 'data/administrative_categories/'
  on :l=, :language, 'Wikipedia language', default: 'en'
end

begin
  options.parse
rescue Slop::MissingOptionError
  puts options
  exit
end

db_path = options[:db_path]
data_path = options[:data_path]
lang = options[:language]

Database.instance.open_database(db_path,:readonly => false)
universal_match = File.readlines(data_path + "#{lang}/universal_match.txt").map(&:chomp)
prefix_match = File.readlines(data_path + "#{lang}/prefix_match.txt").map(&:chomp)
strict_match = File.readlines(data_path + "#{lang}/strict_match.txt").map(&:chomp)
blacklist_regexp = /#{universal_match * "|"}|(\b(#{prefix_match * "|"}))|(\b(#{strict_match * "|"})\b)/i

whitelist = File.readlines(data_path + "#{lang}/whitelist_categories.txt").map(&:chomp)

File.readlines(data_path + "#{lang}/root_administrative.txt").map(&:chomp).each do |root_name|
  root = Category.find_by_name(root_name)
  root.administrative!
  root.children.each do |child|
    next if whitelist.include?(child.name)
    child.administrative!
    child.children.each do |grandchild|
      grandchild.administrative! unless whitelist.include?(grandchild.name)
    end
  end
end

File.readlines(options[:templates]).map(&:to_i).each do |cat_id|
  begin
    Category.find_by_wiki_id(cat_id).administrative!
  rescue Exception
    puts "Missing category with id #{cat_id}."
  end
end

Progress.start(Category.count)
Category.each do |category|
  Progress.step(1)
  category.administrative! if category.name =~ blacklist_regexp
end
Progress.stop

puts "Marking stubs"

blacklisted_count = 0
stub_count = 0
Progress.start(Category.count)
Category.each do |category|
  if category.name =~ /\bstub(s)?\b/i
    category.stub!
    stub_count += 1
  elsif category.administrative?
    blacklisted_count += 1
  end
end
Progress.stop

puts "Blacklisted categories: #{blacklisted_count}"
puts "Stubs: #{stub_count}"

Progress.start(Article.count)
orphaned_articles = 0
special_orphans = Hash.new(0)
samples = []
Article.each do |article|
  Progress.step(1)
  any_categories = (article.categories.count > 0)
  all_rejected = article.categories.all?{|c| c.administrative? }
  if any_categories && all_rejected
    orphaned_articles += 1
    if article.categories.any?{|c| c.name =~ /\bdisamb/i }
      special_orphans[:disamb] += 1
    elsif article.categories.any?{|c| c.name =~ /\bredir/i }
      special_orphans[:redir] += 1
    elsif article.categories.any?{|c| c.name =~ /\blist/i }
      special_orphans[:list] += 1
    elsif article.categories.any?{|c| c.name =~ /\b(index of|set index)/i }
      special_orphans[:index] += 1
    elsif article.categories.any?{|c| c.name =~ /\bdata page/i }
      special_orphans[:data] += 1
    else
      if samples.size < 20 && rand < 0.05
        samples << article
      end
    end
  end
end
Progress.stop
puts "Orphaned articles: #{orphaned_articles}"
puts "Including: "
special_orphans.each do |type,count|
  puts "| #{type} | #{count} |"
end

puts "Samples: "
samples.each do |article|
  puts " * [#{article.name}](http://en.wikipedia.org/wiki/#{article.name.gsub(" ","_")})"
end

Database.instance.close_database
