#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'slop'
require 'cyclopedio/wiki'
require 'progress'
require 'csv'
include Cyclopedio::Wiki

options = Slop.new do
  banner "Usage: #{$PROGRAM_NAME} -d path/to/rod -i eponymous.csv\n" +
    "Load links between articles and their eponymous categories."

  on :d=, :database, 'ROD Database path', required: true
  on :i=, :input, 'File with eponymous links', required: true
end
begin
  options.parse
rescue Slop::MissingOptionError => ex
  puts ex
  puts options
  exit
end

total = 0
total_categories = 0
linked = 0
linked_categories = 0
Database.instance.open_database(options[:database],readonly: false)
at_exit do
  Database.instance.close_database
end
CSV.open(options[:input],"r:utf-8") do |input|
  input.with_progress do |category_id,article_names|
    total_categories += 1
    begin
      category = Category.find_by_wiki_id(category_id.to_i)
      next if category.nil?
      linked_categories += 1
      article_names.split("|").each do |article_name|
        total += 1
        article = Article.find_with_redirect(article_name)
        next if article.nil?
        category.eponymous_articles << article
        article.eponymous_categories << category
        article.eponymous_categories = article.eponymous_categories.to_a.uniq
        article.store
        linked += 1
      end
      category.eponymous_articles = category.eponymous_articles.to_a.uniq
      category.store
    rescue Interrupt
      puts
      break
    rescue Exception => ex
      puts "error #{category_id}:#{article_names}"
      puts ex
      puts ex.backtrace[5]
    end
  end
end
puts "Linked articles: #{linked}/#{total}"
puts "Linked categories: #{linked_categories}/#{total_categories}"
