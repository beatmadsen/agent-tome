require "active_support/core_ext/string/inflections"

module Agent
  module Tome
    module Commands
      class Create
        TRACKING_PARAMS = %w[fbclid gclid fbid mc_cid mc_eid].freeze

        def call(input)
          validate!(input)

          result = {}

          ActiveRecord::Base.transaction do
            article = Article.create!(
              description: input["description"],
              created_at: Time.now
            )

            entry = Entry.create!(
              article: article,
              body: input["body"],
              created_at: Time.now
            )

            process_keywords!(article, input["keywords"] || [])
            web_source_ids = process_web_sources!(entry, input["web_sources"] || [])
            file_source_ids = process_file_sources!(entry, input["file_sources"] || [])
            process_related_articles!(article, input["related_article_ids"] || [])

            result = {
              "article_global_id" => article.global_id,
              "entry_global_id" => entry.global_id,
              "web_source_global_ids" => web_source_ids,
              "file_source_global_ids" => file_source_ids
            }
          end

          result
        end

        private

        def validate!(input)
          raise ValidationError, "Missing description" unless input.key?("description")
          raise ValidationError, "Missing body" unless input.key?("body")

          desc = input["description"]
          raise ValidationError, "description must be a string" unless desc.is_a?(String)
          raise ValidationError, "description cannot be blank" if desc.strip.empty?
          raise ValidationError, "description must be 350 characters or fewer" if desc.length > 350

          body = input["body"]
          raise ValidationError, "body must be a string" unless body.is_a?(String)
          raise ValidationError, "body cannot be blank" if body.strip.empty?

          validate_keywords!(input["keywords"]) if input.key?("keywords")
          validate_web_sources!(input["web_sources"]) if input.key?("web_sources")
          validate_file_sources!(input["file_sources"]) if input.key?("file_sources")
          validate_related_ids!(input["related_article_ids"]) if input.key?("related_article_ids")
        end

        def validate_keywords!(keywords)
          return unless keywords

          raise ValidationError, "keywords must be an array" unless keywords.is_a?(Array)

          keywords.each do |kw|
            raise ValidationError, "keyword must be a non-empty string" unless kw.is_a?(String) && !kw.strip.empty?
          end
        end

        def validate_web_sources!(sources)
          return unless sources

          raise ValidationError, "web_sources must be an array" unless sources.is_a?(Array)

          sources.each do |src|
            raise ValidationError, "web_source url is required" unless src.is_a?(Hash) && src["url"]
            raise ValidationError, "invalid URL: #{src["url"]}" unless UrlNormalizer.valid?(src["url"])
          end
        end

        def validate_file_sources!(sources)
          return unless sources

          raise ValidationError, "file_sources must be an array" unless sources.is_a?(Array)

          sources.each do |src|
            raise ValidationError, "file_source path cannot be empty" if src["path"].to_s.strip.empty?
            raise ValidationError, "file_source system_name cannot be empty" if src["system_name"].to_s.strip.empty?
          end
        end

        def validate_related_ids!(ids)
          return unless ids

          raise ValidationError, "related_article_ids must be an array" unless ids.is_a?(Array)

          ids.each do |id|
            raise ValidationError, "Referenced article not found: #{id}" unless Article.exists?(global_id: id)
          end
        end

        def process_keywords!(article, keywords)
          keywords.each do |kw|
            normalized = normalize_keyword(kw)
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

        def normalize_keyword(kw)
          words = kw.downcase.split("-")
          words[-1] = ActiveSupport::Inflector.singularize(words[-1])
          words.join("-")
        end
      end
    end
  end
end
