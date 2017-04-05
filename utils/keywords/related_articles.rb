#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'slop'
require 'rlp/wiki'
require 'progress'
require 'csv'
require 'set'

options = Slop.new do
  banner "#{$PROGRAM_NAME} -d database -c category -o keywords.csv\n" +
    "Export most related articles for a given category or article\n" +
    "Use -c switch for category,  -n for article or -i for list of articles/categories"

  on :d=,  :database,  "ROD database",  required: true
  on :c=,  :category,  "Name of the category to export"
  on :n=,  :article,  "Name of the article to export"
  on :i=,  :input,  "Input file with names of categories to map"
  on :o=,  :output,  "File with keywords (CSV)",  required: true
  on :t=,  :total,  "Total links in the DB",  as: Integer
  on :r=,  :correlation,  "Minimal correlation eligible for output",  as: Float,  default: 0.5
  on :l=,  :links,  "Minimal number of incoming links eligible for output",  as: Integer,  default: 3
end

begin
  options.parse
rescue => ex
  puts ex
  puts options
  exit
end

if options[:category].nil? && options[:input].nil? && options[:article].nil?
  puts "Either category,  article or input has to be specified"
  puts options
  exit
end

include Rlp::Wiki
MissingPage = Class.new(Exception)

def update_articles(articles, histogram, visited)
  articles.each do |article|
    next if visited.include?(article)
    article.linked_articles.each do |linked_article|
      histogram[linked_article] += 1
    end
    article.linking_articles.each do |linking_article|
      histogram[linking_article] += 1
      visited << linking_article
    end
    visited << article
  end
end

def process_category(category, histogram, visited)
  raise MissingPage if category.nil?
  update_articles(category.articles, histogram, visited)
  category.children.each do |child|
    update_articles(child.articles, histogram, visited)
  end
end

def process_article(article, histogram, visited)
  raise MissingPage if article.nil?
  article.categories.each do |category|
    update_articles(category.articles, histogram, visited)
  end
end

def compute_total
  puts 'Computing total count of links'
  total = 0
  Progress.start(Article.count)
  Article.each do |article|
    Progress.step(1)
    total += article.linked_articles.count + article.linking_articles.count
  end
  Progress.stop
  puts "Total #{total}"
  total
end

def compute_pmi(histogram, visited, total)
  category_sum = 0
  visited.each do |article|
    category_sum += article.linked_articles.count + article.linking_articles.count
  end
  pmi_histogram = {}
  histogram.each do |article, count|
    article_sum = article.linking_articles.count + article.linked_articles.count
    pmi_histogram[article] = Math::log((count.to_f/total)/((article_sum.to_f/total) *
                                                           (category_sum.to_f/total)))
  end
  pmi_histogram
end

Database.instance.open_database(options[:database])
at_exit do
  Database.instance.close_database
end

CSV.open(options[:output], 'w') do |output|
  if options[:total]
    total = options[:total]
  else
    total = compute_total()
  end
  if options[:category] || options[:article]
    histogram = Hash.new(0)
    visited = Set.new
    if options[:category]
      category = Category.find_by_name(options[:category])
      if category.nil?
        puts "No such category '#{options[:category]}'"
        exit
      end
      process_category(category, histogram, visited)
    else
      article = Article.find_by_name(options[:article])
      if article.nil?
        puts "No such article '#{options[:article]}'"
        exit
      end
      process_article(article, histogram, visited)
    end
    pmi_histogram = compute_pmi(histogram, visited, total)
    p pmi_histogram[Article.find_by_name("Rolnictwo")]
    puts 'Most related keywords'
    histogram.sort_by{|_, count| -count }.take(30).each do |article, count|
      puts '%-55s %3i %7.2f' % [article.name, count, pmi_histogram[article]]
    end
    pmi_histogram.select{|_, v| v > options[:correlation] }.sort_by{|_, v| -v}.each do |article, value|
      next if article.linking_articles.count < options[:links]
      output << [article.name, "%.3f" % value, article.linking_articles.count]
    end
  else
    CSV.open(options[:input], "r:utf-8") do |input|
      input.with_progress do |name, *rest|
        totals = Hash.new(0)
        rest.each do |category_or_article|
          histogram = Hash.new(0)
          visited = Set.new
          _, type, name = *category_or_article.match(/^([^:]*):(.*)$/)
          begin
            if type == "Category"
              process_category(Category.find_by_name(name), histogram, visited)
            else
              process_article(Article.find_by_name(name), histogram, visited)
            end
          rescue MissingPage
            puts "No page: #{category_or_article}"
          end
          pmi_histogram = compute_pmi(histogram, visited, total)
          pmi_histogram.each do |article, value|
            totals[article] += value
          end
        end
        totals.each {|c, _| totals[c] /= rest.size }
        output_line = [name]
        totals.select{|_, v| v > options[:correlation] }.sort_by{|_, v| -v}.each do |article, value|
          output_line.concat([article.name, "%.3f" % value])
        end
        output << output_line
      end
    end
  end
end

