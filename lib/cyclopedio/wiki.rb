require 'rod'

module Cyclopedio
  module Wiki
    class Database < Rod::Database
    end

    class Model < Rod::Model
      database_class Database
    end
  end
end

require 'cyclopedio/wiki/version'
require 'cyclopedio/wiki/page'
require 'cyclopedio/wiki/article'
require 'cyclopedio/wiki/category'
require 'cyclopedio/wiki/anchor'
require 'cyclopedio/wiki/translation'
require 'cyclopedio/wiki/redirect'
require 'cyclopedio/wiki/occurrence'
require 'cyclopedio/wiki/disambiguation'
