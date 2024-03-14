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

      def group_relatedness(primary_concept, concepts)
        #@group_relatedness ||= {}
        #if @group_relatedness.has_key?(concepts)
        #  return @group_relatedness[concepts]
        #end
        relatedness = 0.0
        weight_sum = 0.0
        concepts.each do |concept,weight|
          next if concept == self
          relatedness += self.relatedness(primary_concept, concept) * weight
          weight_sum += weight
        end
        #@group_relatedness[concepts] = relatedness / weight_sum
        if weight_sum > 0
          relatedness / weight_sum
        else
          0.0
        end
      end

      def context_relatedness(occurrences)
        tuples = occurrences.map{|o| [o.article, o.anchor]}
          #reject{|t| t[1].stop_link?}
        # first relatedness computation
        group = tuples.map{|t| [t[0],1.0]}
        group.each.with_index do |pair,pair_index|
          concept,weight = pair
          tuples[pair_index] << self.group_relatedness(concept, group)
        end
        # second - weighted relatedness computation
        weight_total = 0.0
        group = tuples.map do |concept,anchor,relatedness|
          weight = (anchor.link_probability + relatedness) / 2
          weight_total += weight
          [concept,weight]
        end
        # concept - relatedness map
        map = {}
        tuples.each do |concept,anchor,relatedness|
          map[concept] = self.group_relatedness(concept, group)
        end
        {:concepts => map, :goodness => weight_total}
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
