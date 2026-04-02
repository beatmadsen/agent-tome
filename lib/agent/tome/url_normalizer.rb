require "uri"

module Agent
  module Tome
    module UrlNormalizer
      TRACKING_PARAMS = %w[
        fbclid gclid fbid mc_cid mc_eid
      ].freeze

      def self.normalize(url)
        uri = URI.parse(url)
        return url unless uri.query

        params = URI.decode_www_form(uri.query)
        filtered = params.reject do |k, _|
          k.start_with?("utm_") || TRACKING_PARAMS.include?(k)
        end

        uri.query = filtered.empty? ? nil : URI.encode_www_form(filtered)
        uri.to_s
      rescue URI::InvalidURIError
        url
      end

      def self.valid?(url)
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
