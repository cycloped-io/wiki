#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'slop'
require 'cyclopedio/wiki'
require 'progress'
require 'csv'
require 'fileutils'
include Cyclopedio::Wiki

# This script creates the database and loads the pages
# (articles, redirects and categories).

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

Database.instance.create_database(db_path)
TYPES = {0 => :article, 1 => :category, 2 => :redirect, 3 => :disambiguation, 4 => :template}
index = 0
csv = CSV
FileUtils.mkdir_p("log") unless File.exist?("log")
errors = File.open("log/load_page_errors.log","w")
open("#{data_path}/page.csv","r:utf-8") do |file|
  Progress.start(file.size)
  file.each_with_index do |line,index|
    begin
      Progress.set(file.pos)
      #next if index < 261000
      wiki_id, name, type, _ = csv.parse(line).first
      wiki_id = wiki_id.to_i
      type = TYPES[type.to_i]
      case type
      when :article
        klass = Article
      when :category
        klass = Category
      when :redirect
        klass = Redirect
      when :disambiguation
        klass = Disambiguation
      when :template
        next
      else
        next
      end
      page = klass.new(:name => name, :wiki_id => wiki_id)
      page.store
    rescue Interrupt
      puts
      break
    rescue Exception => ex
      puts line
      puts ex
      puts ex.backtrace[0]
      errors.puts line
      errors.puts ex
    end
    #puts "#{index} #{Time.now}" if index % 1000 == 0
    #break if index > 10
  end
  Progress.stop
end
Database.instance.close_database
errors.close

# Show what was loaded.
Database.instance.open_database(db_path)
[Article,Category,Redirect,Disambiguation].each do |type|
  puts "#{type} count: #{type.count}"
  type.each.with_index do |page,index|
    puts "%-20s %-20s" % [page.class,page.name]
    break if index > 10
  end
end
Database.instance.close_database
