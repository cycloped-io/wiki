module Cyclopedio
  module Relatedness
    class Jaccard < Base
      protected
      def compute_relatedness(article_1, article_2)
        links_1 = article_1.linking_articles
        links_2 = article_2.linking_articles
        intersection_size = links_1.intersection_size(links_2)
        union_size = links_1.size + links_2.size - intersection_size
        if union_size > 0
          1.0 / (1 - Math::log10(intersection_size.to_f / union_size))
        else
          0
        end
      end
    end
  end
end
