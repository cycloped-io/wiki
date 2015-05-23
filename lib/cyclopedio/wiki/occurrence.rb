module Cyclopedio
  module Wiki
    # The occurrences links unified anchor with one of the articles
    # it links to. They are fetched from the in +anchor.csv+ file.
    class Occurrence < Model
      # The number of occurrences of the +anchor+ pointing to the +article+.
      # It is the (3) field in the +anchor.csv+ file.
      field :count, :integer

      # The +article+ this occurrence points to.
      # Its +wiki_id+ is the (2) field in the +anchor.csv+ file.
      has_one :article

      # The anchor of this occurrence, that is the name of the link.
      has_one :anchor

      attr_accessor :measure
    end
  end
end
