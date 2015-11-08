# encoding: utf-8
require 'set'

module  Cyclopedio
  module Wiki
    # The articles are kept in +page.csv+ file and their type
    # is set to (1) (the type is the (3) field in the file).
    class Article < Page
      SYMBOL_RE = /^\p{P}+$/

      # The kind of page.
      # This might be one of:
      # * +nil+ - the initial status
      # * +:list+ - list page
      # * +:disambiguation+ - disambiguation page
      # * +:other+ - index, outline, glossary, data page
      field :status, :object

      # The definition (the first sentence) of the article.
      field :definition, :string

      # The tagged definition of the article.
      field :tagged_definition, :string

      # List of Cyc types (their external ids) that classify this article. This
      # is computed automatically and is the main purpose of cycloped-io.
      field :types, :object

      # List of infoboxes appearing in the article (as Ruby Array).
      field :infoboxes, :object

      # The categories this article belongs to.
      # Their +wiki_ids+ are the (1) field in the +cagtegorylink.csv+ file.
      has_many :categories

      # The articles linking to this article.
      # Their +wiki_ids+ are the (1) field in the +pagelink.csv+ file.
      has_many :linking_articles, :class_name => "Cyclopedio::Wiki::Article"

      # The articles this article links to.
      # Their +wiki_ids+ are the (2) field in the +pagelink.csv+ file.
      has_many :linked_articles, :class_name => "Cyclopedio::Wiki::Article"

      # The text values used in links pointing to this article.
      # They are stored in the +anchor.csv+ file.
      has_many :occurrences

      # The categories which are equivalent to the article.
      # Its +wiki_id+ is the (1) field in the +equivalence.csv+ file.
      # In rare cases there are many categories that are equivalent to one
      # article.
      has_many :eponymous_categories, :class_name => "Cyclopedio::Wiki::Category"

      # Returns the most popular target of anchors with given label.
      def self.find_by_label(label)
        anchor = Anchor.find_by_value(label)
        return nil unless anchor
        occurrence = anchor.occurrences.sort_by{|o| -o.count }.first
        return nil unless occurrence
        occurrence.article
      end

      # Indicates if article is regular (not list, dissambiguation page, etc.)
      def regular?
        status.nil?
      end
    end
  end
end
