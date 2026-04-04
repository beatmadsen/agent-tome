module Agent
  module Tome
    module InputValidator
      def self.validate_keywords!(keywords)
        raise ValidationError, "keywords must be an array" unless keywords.is_a?(Array)

        keywords.each do |kw|
          raise ValidationError, "keyword must be a non-empty string" unless kw.is_a?(String) && !kw.strip.empty?
        end
      end

      def self.validate_web_sources!(sources)
        raise ValidationError, "web_sources must be an array" unless sources.is_a?(Array)

        sources.each do |src|
          raise ValidationError, "web_source url is required" unless src.is_a?(Hash) && src["url"]
          raise ValidationError, "invalid URL: #{src["url"]}" unless UrlNormalizer.valid?(src["url"])
        end
      end

      def self.validate_file_sources!(sources)
        raise ValidationError, "file_sources must be an array" unless sources.is_a?(Array)

        sources.each do |src|
          raise ValidationError, "file_source path cannot be empty" if src["path"].to_s.strip.empty?
          raise ValidationError, "file_source system_name cannot be empty" if src["system_name"].to_s.strip.empty?
        end
      end

      def self.validate_related_ids!(ids)
        raise ValidationError, "related_article_ids must be an array" unless ids.is_a?(Array)

        ids.each do |id|
          raise ValidationError, "Referenced article not found: #{id}" unless Article.exists?(global_id: id)
        end
      end
    end
  end
end
