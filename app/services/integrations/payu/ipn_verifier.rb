module Integrations
  module Payu
    class IpnVerifier
      # @param raw_body [String] raw HTTP request body (before any parsing)
      # @param signature_header [String] value of OpenPayu-Signature header
      # @param md5key [String] Second Key from PayU panel
      def self.valid?(raw_body:, signature_header:, md5key:)
        new(raw_body, signature_header, md5key).valid?
      end

      def initialize(raw_body, signature_header, md5key)
        @raw_body = raw_body
        @signature_header = signature_header
        @md5key = md5key
      end

      def valid?
        return false if @signature_header.blank? || @md5key.blank?

        incoming_signature = extract_signature
        return false if incoming_signature.blank?

        expected = Digest::MD5.hexdigest("#{@raw_body}#{@md5key}")
        ActiveSupport::SecurityUtils.secure_compare(incoming_signature, expected)
      end

      private

      # Header format: "sender=checkout;signature=HEXHASH;algorithm=MD5;content=DOCUMENT"
      def extract_signature
        @signature_header
          .split(";")
          .map { |pair| pair.split("=", 2) }
          .to_h["signature"]
      end
    end
  end
end
