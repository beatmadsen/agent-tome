module Agent
  module Tome
    module RelatedArticleLinker
      def self.call(article, related_ids)
        related_ids.each do |target_id|
          raise ValidationError, "An article cannot reference itself" if target_id == article.global_id

          target = Article.find_by!(global_id: target_id)
          ArticleReference.find_or_create_by!(
            source_article: article,
            target_article: target
          ) do |ref|
            ref.created_at = Time.now
          end
        end
      end
    end
  end
end
