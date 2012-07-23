require 'base64'
require 'openssl'
require 'uri'

module Paypal
  module Permissions
    module Oauth

      # Note: OAuth does not encode '.', but PayPal does.
      OAUTH_RESERVED_CHARACTERS = /[^a-zA-Z0-9\_]/
      OAUTH_SIGNATURE_METHOD    = 'HMAC-SHA1'

      # Create the X-PP-AUTHORIZATION header
      def generate_signature(token, token_secret, http_method, endpoint)
        raise "Invalid HTTP Method. Valid values: GET, POST, DELETE, UPDATE." unless ['GET','POST','DELETE','UPDATE'].include? http_method

        timestamp = Time.now.to_i.to_s
        signature_key = "#{@password}&#{oauth_escape(token_secret)}"

        oauth_params = {
          'oauth_consumer_key'      => @userid,
          'oauth_signature_method'  => OAUTH_SIGNATURE_METHOD,
          'oauth_timestamp'         => timestamp,
          'oauth_token'             => token,
          'oauth_version'           => '1.0',
        }

        input_string = "#{http_method}&#{oauth_escape(endpoint)}&"
        input_string += oauth_params.map{ |k,v| "#{k}=#{v}" }.join('&')

        # HMAC SHA1
        digest_key = ::Digest::SHA1.digest(signature_key)
        sha1_hash  = ::OpenSSL::Digest::Digest.new('sha1')
        signature  = ::OpenSSL::HMAC.hexdigest(sha1_hash, digest_key, input_string)

        "timestamp=#{timestamp},token=#{token},signature=#{signature}"
      end

      def oauth_escape(value)
        URI::escape(value.to_s, OAUTH_RESERVED_CHARACTERS)
      end
    end
  end
end
