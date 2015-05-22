task :default => [:"load:pages", :"load:languages", :"load:redirects", :"load:categories", :"load:offsets"]

wikipedia_path = ENV['WIKI_DATA']
db = ENV['WIKI_DB']
lang = ENV['WIKI_LANG']
if wikipedia_path.nil?
  puts "WIKI_DATA has to be set"
  exit
end
if db.nil?
  puts "WIKI_DB has to be set"
  exit
end
if lang.nil?
  puts "Language not specified, assuming English (en)"
  lang = "en"
end


desc "Download dumps"
task :download do
  puts `./utils/download.rb -w #{wikipedia_path} -l #{lang}`
end

namespace :load do
  desc "Load pages"
  task :pages do
    puts `./utils/load/init.rb -w #{wikipedia_path} -d #{db}`
  end

  desc "Load language links"
  task :languages do
    puts `./utils/load/translations.rb -w #{wikipedia_path} -d #{db} -l en:nl:de:sv:fr:it:es:ru:pl:ja`
  end

  desc "Load redirects"
  task :redirects do
    puts `./utils/load/redirects.rb -w #{wikipedia_path} -d #{db}`
  end

  desc "Load category links"
  task :categories do
    puts `./utils/load/categories.rb -w #{wikipedia_path} -d #{db}`
  end

  desc "Load page offsets"
  task :offsets do
    puts `./utils/load/offsets.rb -w #{wikipedia_path} -d #{db}`
  end

  desc 'Load head nouns'
  task :heads do
    puts `./utils/categories/load_parses.rb -d #{db} -f #{wikipedia_path}/categories_with_heads.csv`
  end
end

namespace :administrative do
  wikipedia_path = ENV['WIKI_DATA']
  db = ENV['WIKI_DB']
  if wikipedia_path.nil?
    puts "WIKI_DATA has to be set"
    exit
  end
  if db.nil?
    puts "WIKI_DB has to be set"
    exit
  end

  task :all => [:"administrative:template", :"administrative:mark", :"administrative:export"]

  desc "Find categories containing the administrative template"
  task :template do
    puts `./utils/categories/find_administrative_template.rb -f #{wikipedia_path}/templates.csv -o #{wikipedia_path}/administrative_template_ids.csv`
  end

  desc "Mark administrative templates in the ROD database"
  task :mark do
    puts `./utils/categories/mark_administrative.rb -d #{db} -t #{wikipedia_path}/administrative_template_ids.csv`
  end

  desc "Export administrative categories"
  task :export do
    puts `./utils/categories/export_administrative.rb -d #{db} -o #{wikipedia_path}`
  end
end

namespace :special_pages do
  wikipedia_path = ENV['WIKI_DATA']
  db = ENV['WIKI_DB']
  if wikipedia_path.nil?
    puts "WIKI_DATA has to be set"
    exit
  end
  if db.nil?
    puts "WIKI_DB has to be set"
    exit
  end

  task :all => [:"special_pages:lists", :"special_pages:disambiguation", :"special_pages:indexes"]

  desc "Find list pages"
  task :lists do
    puts `./utils/special_pages/identify_lists.rb -o #{wikipedia_path}/list_pages.csv -d #{db}`
  end

  desc "Find disambiguation pages"
  task :disambiguation do
    puts `./utils/special_pages/identify_disambiguation_pages.rb -o #{wikipedia_path}/disambiguation_pages.csv -d #{db}`
  end

  desc "Find indexes, outlines, data pages"
  task :indexes do
    puts `./utils/special_pages/identify_indexes.rb -o #{wikipedia_path}/indexes_pages.csv -d #{db}`
  end
end


namespace :definitions do
  wikipedia_path = ENV['WIKI_DATA']
  db = ENV['WIKI_DB']
  if wikipedia_path.nil?
    puts "WIKI_DATA has to be set"
    exit
  end
  if db.nil?
    puts "WIKI_DB has to be set"
    exit
  end

  task :all => [:"definitions:load"]

  desc "Load parsed definitions with extracted types"
  task :load do
    puts `./utils/load/types.rb -w #{wikipedia_path}/parsed_articles_with_types.csv -d #{db}`
  end

end
