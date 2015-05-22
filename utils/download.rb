#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'slop'
require 'fileutils'
require 'net/http'
require 'progress'
require 'digest/md5'
require 'colors'

options = Slop.new do
  banner "Usage: #{$PROGRAM_NAME} -w data_path [-l language_code] [-f files.txt] [-m mirror]\n" +
    "Downloads Wikipedia SQL dumps used in the extraction process"

  on :w=, :data_path, 'Wikipedia sql dumps storage path', required: true
  on :l=, :language, 'Language edition of Wikipedia (default: en)'
  on :f=, :files, 'List of files to download (default: data/wikipedia_dumps.txt)'
  on :m=, :mirror, 'Mirror used to download the dumps (default: http://dumps.wikimedia.org)'
  on :d=, :date, 'The specific version Wikipedia dump (default: latest)'
end

begin
  options.parse
rescue Slop::MissingOptionError => ex
  puts ex
  puts options
  exit
end

FileUtils.mkdir_p(options[:data_path])
dumps = options[:files] || "data/wikipedia_dumps.txt"
unless File.exist?(dumps)
  puts "File#{dumps} does not exist"
  puts options
  exit
end

url = options[:mirror] || "http://dumps.wikimedia.org"
unless url =~ /^http:\/\//
  puts "Mirror URL requires protocol (e.g. http://)"
  puts options
  exit
end
url = url + "/" if url[-1] != "/"

lang = options[:language] || "en"
unless lang =~ /^\w{2,3}$/
  puts "Invalid language #{lang}"
  puts options
  exit
end

def download(url,path,continue=true)
  puts url
  uri = URI.parse(url)
  headers = {}
  offset = 0
  mode = "w"
  if continue
    if File.exist?(path)
      mode = "a"
      offset = File.size(path)
      headers['Range'] = "#{offset}-"
    end
  end
  File.open(path,mode) do |output|
    Net::HTTP.start(uri.host,uri.port) do |http|
      response = http.head(uri.path)
      raise "HTTP error: #{response.code} for #{url}" if response.code != "200"
      Progress.start(response['content-length'].to_i-offset)
      http.get(uri.path,headers) do |chunk|
        output.write(chunk)
        Progress.step(chunk.size)
      end
    end
    Progress.stop
  end
end

def wiki_url(url,file,lang,date)
  url + "#{lang}wiki/#{date}/#{lang}wiki-#{date}-#{file}"
end


data_path = options[:data_path]
files = File.readlines(dumps).map(&:chomp)
date = options[:date] || "latest"
checksums_file = "md5sums.txt"
checksums_path = File.join(data_path,checksums_file)
files.delete(checksums_file)
download(wiki_url(url,checksums_file,lang,date),checksums_path,false)
checksums = Hash[File.readlines(checksums_path).map{|l| l.split(" ").reverse}]
main_article_file = "pages-articles.xml.bz2"

files.each do |file_name|
  begin
    path = File.join(data_path,file_name)
    if file_name == main_article_file && File.exist?(path.sub(/\.bz2/,""))
      puts "#{main_article_file} extracted. Skipping. Remove that file to force download.".hl(:yellow)
      next
    end
    checksum_key = checksums.keys.grep(/^#{lang}wiki-\d{8}-#{file_name}$/).first
    if checksum_key
      if File.exist?(path)
        checksum = checksums[checksum_key]
        computed_checksum = Digest::MD5.file(path).hexdigest
        if checksum == computed_checksum
          puts "#{file_name} present. Skipping.".hl(:green)
          next
        else
          puts "#{file_name} has invalid checksum. Downloading.".hl(:yellow)
        end
      end
    else
      puts "Missing checksum for #{file_name}. Forcing download".hl(:yellow)
    end
    download(wiki_url(url,file_name,lang,date),File.join(data_path,file_name))
    if File.exist?(path)
      if checksum_key
        checksum = checksums[checksum_key]
        computed_checksum = Digest::MD5.file(path).hexdigest
        if checksum == computed_checksum
          puts "Checksum OK".hl(:green)
        else
          STDERR.puts "Checksum invalid for #{file_name}!".hl(:red)
        end
      else
        puts "#{file_name} downloaded. Cannot compute checksum."
      end
    else
      STDERR.puts "#{file_name} not downloaded!".hl(:red)
    end
  rescue Interrupt
    puts
    break
  rescue Exception => ex
    puts ex.to_s.hl(:red)
    puts ex.backtrace[0..5]
  end
end
