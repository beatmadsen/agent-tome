module Agent
  module Tome
    module GlobalId
      BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
      PATTERN = /\A[1-9A-HJ-NP-Za-km-z]{7}\z/

      def self.generate
        Array.new(7) { BASE58_ALPHABET[rand(58)] }.join
      end

      def self.valid?(id)
        id.is_a?(String) && PATTERN.match?(id)
      end
    end
  end
end
