require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'

module Paypal
  module Permissions
    class Paypal
      include Oauth

      attr_accessor :userid, :password, :signature, :application_id, :mode

      SANDBOX_SERVER = 'https://svcs.sandbox.paypal.com/Permissions/'
      PRODUCTION_SERVER = 'https://svcs.paypal.com/Permissions/'
      API_VERSION = '74.0'

      SANDBOX_GRANT_PERMISSION_URL = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_grant-permission&request_token='
      PRODUCTION_GRANT_PERMISSION_URL = 'https://www.paypal.com/cgi-bin/webscr?cmd=_grant-permission&request_token='

      PERMISSIONS = {
        :express_checkout => 'EXPRESS_CHECKOUT',
        :direct_payment => 'DIRECT_PAYMENT',
        :settlement_consolidation => 'SETTLEMENT_CONSOLIDATION',
        :settlement_reporting => 'SETTLEMENT_REPORTING',
        :auth_capture => 'AUTH_CAPTURE',
        :mobile_checkout => 'MOBILE_CHECKOUT',
        :billing_agreement => 'BILLING_AGREEMENT',
        :reference_transaction => 'REFERENCE_TRANSACTION',
        :air_travel => 'AIR_TRAVEL',
        :mass_pay => 'MASS_PAY',
        :transaction_details => 'TRANSACTION_DETAILS',
        :transaction_search => 'TRANSACTION_SEARCH',
        :recurring_payments => 'RECURRING_PAYMENTS',
        :account_balance => 'ACCOUNT_BALANCE',
        :encrypted_website_payments => 'ENCRYPTED_WEBSITE_PAYMENTS',
        :refund => 'REFUND',
        :non_referenced_credit => 'NON_REFERENCED_CREDIT',
        :button_manager => 'BUTTON_MANAGER',
        :manage_pending_transaction_status => 'MANAGE_PENDING_TRANSACTION_STATUS',
        :recurring_payment_report => 'RECURRING_PAYMENT_REPORT',
        :extended_pro_processing_report => 'EXTENDED_PRO_PROCESSING_REPORT',
        :exception_processing_report => 'EXCEPTION_PROCESSING_REPORT',
        :account_management_permission => 'ACCOUNT_MANAGEMENT_PERMISSION',
      }

      # Credentials: UserID, Password, Signature, Application ID
      def initialize(userid, password, signature, application_id, mode = :production)
        raise "Mode must be :sandbox or :production" unless [:sandbox, :production].include? mode
        @userid = userid
        @password = password
        @signature = signature
        @application_id = application_id
        @mode = mode
      end

      # Create a "Request Permissions" URL. After requesting permissions, send the user to the URL
      # so they can grant permissions. The user will be redirected back to the :callback_url.
      def request_permissions(permissions_scopes, callback_url, language = 'en')
        url = create_url('RequestPermissions')

        request_data = {'callback' => callback_url, 'language' => language }
        permissions_scopes.each_with_index { |ps,index| request_data["scope(#{index})"] = PERMISSIONS[ps] }
        data = call(url, request_data)

        raise ::Paypal::Permissions::FaultMessage.new(data) unless data['token']

        # Redirect URL:
        # https://www.paypal.com/cgi-bin/webscr?cmd=_grant-permission&request_token= + token
        {
          permissions_url: (mode == :production ? PRODUCTION_GRANT_PERMISSION_URL : SANDBOX_GRANT_PERMISSION_URL) + data['token'],
          token: data['token'],
        }
      end

      # After a callback, lookup the access token and token secret using the :token and :verification from
      # the callback URL.
      def get_access_token(token, verifier)
        url = create_url('GetAccessToken')
        data = call(url, { 'token' => token, 'verifier' => verifier })

        raise ::Paypal::Permissions::FaultMessage.new(data) unless (data['token'] && data['tokenSecret'])

        {
          token:        data['token'],
          token_secret: data['tokenSecret'],
          scopes:       parse_scopes(data),
        }
      end

      # Lookup the permissions granted to a given token.
      def lookup_permissions(token)
        url = create_url('GetPermissions')
        data = call(url, { 'token' => token })

        paypal_scopes = parse_scopes(data)
        raise ::Paypal::Permissions::FaultMessage.new(data) if paypal_scopes.empty?

        { scopes: paypal_scopes }
      end

      # Cancel the permissions granted to the given token
      def cancel_permissions(token)
        url = create_url('CancelPermissions')
        data = call(url, { 'token' => token })
        true
      end

      protected

      def create_url(endpoint)
        (mode == :production ? PRODUCTION_SERVER : SANDBOX_SERVER) + endpoint
      end

      def call(url, params={})
        headers = {
          'X-PAYPAL-SECURITY-USERID' => @userid,
          'X-PAYPAL-SECURITY-PASSWORD' => @password,
          'X-PAYPAL-SECURITY-SIGNATURE' => @signature,
          'X-PAYPAL-REQUEST-DATA-FORMAT' => 'NV',
          'X-PAYPAL-RESPONSE-DATA-FORMAT'=> 'NV',
          'X-PAYPAL-APPLICATION-ID' => @application_id,
          'Content-Type' => 'application/x-www-form-urlencoded',
        }
        params['requestEnvelope.errorLanguage'] = 'en_US'
        data = params.map{ |k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join('&')
        data = URI.encode_www_form(params)

        endpoint = URI(url)
        timeout(30) do
          http = Net::HTTP.new(endpoint.host, endpoint.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if mode == :sandbox
          response = http.post(endpoint.request_uri, data, headers)
          code = response.code

          case code.to_i
          when 200
            data = get_hash(response.body)
            raise ::Paypal::Permissions::FaultMessage.new(data) if data['responseEnvelope.ack'] == 'Failure'
            return data
          when 500
            raise ::Paypal::Permissions::InternalServerError.new(response.body)
          else
            raise ::Paypal::Permissions::UnknownResponse.new(code.to_i, response.body)
          end
        end
      end

      private

      # Gets a hash from a string, with a set of name value pairs joined by '='
      # and concatenated with '&'
      def get_hash(string)
        hash = {}
        string.split('&').collect { |pair| pair.split('=') }.each { |a|
          hash[a[0]] = URI.unescape(a[1])
        }
        return hash
      end

      # Parse out the scopes from the PayPal response
      def parse_scopes(data)
        scopes = []
        scopes << data['scope'] if data['scope'] # If there is only one scope

        i = 0
        while (data["scope(#{i})"]) do
          scopes << data["scope(#{i})"]; i = i + 1
        end # For multiple scopes

        # Convert to symbols
        scopes.collect { |paypal_scope| PERMISSIONS.select { |k,val| val == paypal_scope }.keys.first }
      end
    end
  end
end