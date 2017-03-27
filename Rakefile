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
    puts "Loading pages"
    puts `./utils/load/init.rb -w #{wikipedia_path} -d #{db}`
  end

  desc "Load language links"
  task :languages do
    puts "Loading languages"
    puts `./utils/load/translations.rb -w #{wikipedia_path} -d #{db} -l en:nl:de:sv:fr:it:es:ru:pl:ja`
  end

  desc "Load redirects"
  task :redirects do
    puts "Loading redirects"
    puts `./utils/load/redirects.rb -w #{wikipedia_path} -d #{db}`
  end

  desc "Load category links"
  task :categories do
    puts "Loading categories"
    puts `./utils/load/categories.rb -w #{wikipedia_path} -d #{db}`
  end

  desc "Load page offsets"
  task :offsets do
    puts "Loading offsets"
    puts `./utils/load/offsets.rb -w #{wikipedia_path} -d #{db}`
  end

  desc 'Load head nouns'
  task :heads do
    puts `./utils/categories/load_parses.rb -d #{db} -f #{wikipedia_path}/categories_with_heads.csv`
  end

  desc 'Load eponymous links from templates'
  task :eponymous_templates do
    puts `./utils/load/eponymous.rb -d #{db} -i #{wikipedia_path}/eponymous_from_templates_to_load.csv`
  end

  desc 'Load eponymous links from compound categories'
  task :eponymous_compounds do
    puts `./utils/load/eponymous.rb -d #{db} -i #{wikipedia_path}/eponymous_from_compound_to_load.csv`
  end

  desc 'Load infoboxes'
  task :infoboxes do
    puts `./utils/load/infoboxes.rb -d #{db} -i #{wikipedia_path}/infoboxes.csv`
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

namespace :eponymous do
  desc "Convert list of eponymous template matches into loadable files"
  task :templates do
    puts `./utils/categories/export_eponymous.rb -d #{db} -f #{wikipedia_path}/eponymous_from_templates.csv -o #{wikipedia_path}/eponymous_from_templates_to_load.csv`
  end

  desc "Convert list of eponymy links extracted from compound categories to common format"
  task :compound do
    data,db = get_params
    puts `./utils/categories/convert_eponymous.rb -d #{db} -o #{data}/eponymous_from_compound_to_load.csv -i #{data}/eponymous_from_compound.csv`
  end
end
