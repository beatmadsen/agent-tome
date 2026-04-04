module Agent
  module Tome
    module Commands
      class Addend
        def initialize(article_global_id:)
          @article_global_id = article_global_id
        end

        def call(input)
          article = Article.find_by(global_id: @article_global_id)
          raise NotFoundError, "Article not found: #{@article_global_id}" unless article

          validate!(input)

          result = {}

          ActiveRecord::Base.transaction do
            entry = Entry.create!(
              article: article,
              body: input["body"].to_s.strip.empty? ? nil : input["body"],
              created_at: Time.now
            )

            process_keywords!(article, input["keywords"] || [])
            web_source_ids = process_web_sources!(entry, input["web_sources"] || [])
            file_source_ids = process_file_sources!(entry, input["file_sources"] || [])
            process_related_articles!(article, input["related_article_ids"] || [])

            result = {
              "entry_global_id" => entry.global_id,
              "web_source_global_ids" => web_source_ids,
              "file_source_global_ids" => file_source_ids
            }
          end

          result
        end

        private

        def validate!(input)
          body = input["body"]
          if body && !body.to_s.strip.empty?
            return
          end

          keywords = input["keywords"] || []
          web_sources = input["web_sources"] || []
          file_sources = input["file_sources"] || []
          related = input["related_article_ids"] || []

          if body.is_a?(String) && body.strip.empty?
            raise ValidationError, "body cannot be blank"
          end

          if keywords.empty? && web_sources.empty? && file_sources.empty? && related.empty?
            raise ValidationError, "At least one field must be substantively present"
          end

          validate_keywords!(keywords) if keywords.any?
          validate_web_sources!(web_sources) if web_sources.any?
          validate_file_sources!(file_sources) if file_sources.any?
          validate_related_ids!(input["related_article_ids"]) if input.key?("related_article_ids")
        end

        def validate_keywords!(keywords)
          keywords.each do |kw|
            raise ValidationError, "keyword must be a non-empty string" unless kw.is_a?(String) && !kw.strip.empty?
          end
        end

        def validate_web_sources!(sources)
          sources.each do |src|
            raise ValidationError, "invalid URL: #{src["url"]}" unless UrlNormalizer.valid?(src["url"].to_s)
          end
        end

        def validate_file_sources!(sources)
          sources.each do |src|
            raise ValidationError, "file_source path cannot be empty" if src["path"].to_s.strip.empty?
            raise ValidationError, "file_source system_name cannot be empty" if src["system_name"].to_s.strip.empty?
          end
        end

        def validate_related_ids!(ids)
          return unless ids

          ids.each do |id|
            raise ValidationError, "Referenced article not found: #{id}" unless Article.exists?(global_id: id)
          end
        end

        def process_keywords!(article, keywords)
          keywords.each do |kw|
            normalized = KeywordNormalizer.call(kw)
            keyword = Keyword.find_or_create_by!(term: normalized) do |k|
              k.created_at = Time.now
            end
            ArticleKeyword.find_or_create_by!(article: article, keyword: keyword) do |ak|
              ak.created_at = Time.now
            end
          end
        end

        def process_web_sources!(entry, sources)
          sources.map do |src|
            normalized_url = UrlNormalizer.normalize(src["url"])
            ws = WebSource.find_or_create_by!(url: normalized_url) do |w|
              w.global_id = GlobalId.generate
              w.title = src["title"]
              w.fetched_at = src["fetched_at"] ? Time.parse(src["fetched_at"]) : nil
              w.created_at = Time.now
            end
            EntryWebSource.find_or_create_by!(entry: entry, web_source: ws) do |ews|
              ews.created_at = Time.now
            end
            ws.global_id
          end
        end

        def process_file_sources!(entry, sources)
          sources.map do |src|
            fs = FileSource.find_or_create_by!(path: src["path"], system_name: src["system_name"]) do |f|
              f.global_id = GlobalId.generate
              f.created_at = Time.now
            end
            EntryFileSource.find_or_create_by!(entry: entry, file_source: fs) do |efs|
              efs.created_at = Time.now
            end
            fs.global_id
          end
        end

        def process_related_articles!(article, related_ids)
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
end
