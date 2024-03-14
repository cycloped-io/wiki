# encoding: utf-8
module Cyclopedio
  module Wiki
    # The data about anchors is kept in +anchor.csv+ and +anchro_occurrences.csv+
    # files. The first captuers the data about actual links to articles,
    # while the second captures the statistics of n-gram occurrences
    # in articles (with and without anchors).
    class Anchor < Model
      # The value of the anchor.
      # It is the (1) field in the +anchor_occurrence.csv+ file.
      field :value, :string, :index => :hash, :cache_size => 128 * 1024 * 1024

      # The number of times anchor ngram is used as a link.
      # It is the (2) field in the +anchor_occurrence.csv+ file.
      field :linked_count, :integer

      # The number of times anchor ngram appears in Wikipedia.
      # It is computed from the tokens.tsv file.
      field :unlinked_count, :integer

      # The occurrences of the anchor pointing to different articles.
      # They are found in the +anchor.csv+ file.
      has_many :occurrences

      def link_probability
        return @link_probability if defined?(@link_probability)
        @link_probability = self.linked_count.to_f/(self.unlinked_count)
      end
    end
  end
end
