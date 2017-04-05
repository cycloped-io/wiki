module Cyclopedio
  module Relatedness
    class Base
      def initialize
        @cache = Hash.new{|h,e| h[e] = {} }
      end

      def relatedness(article_1, article_2)
        value = get_value(article_1, article_2)
        if value.nil?
          value = compute_relatedness(article_1, article_2)
          memoize_value(article_1, article_2, value)
        end
        value
      end

      protected
      def compute_relatedness(article_1, article_2)
        raise "Not implemented in the base class"
      end

      private
      def memoize_value(article_1, article_2, value)
        id_1, id_2 = get_ids(article_1, article_2)
        @cache[id_1][id_2] = value
      end

      def get_value(article_1, article_2)
        id_1, id_2 = get_ids(article_1, article_2)
        if @cache.has_key?(id_1)
          if @cache[id_1].has_key?(id_2)
            return @cache[id_1][id_2]
          end
        end
        return nil
      end

      def get_ids(article_1, article_2)
        rod_id_1 = article_1.rod_id
        rod_id_2 = article_2.rod_id
        rod_id_1, rod_id_2 = rod_id_2, rod_id_1 if rod_id_1 > rod_id_2
        [rod_id_1, rod_id_2]
      end
    end
  end
end
