module Paypal
  module Permissions
    # Base error class
    class Error < Exception; end

    # PayPal returned a 500 Internal Server Error. Retry?
    class InternalServerError < ::Paypal::Permissions::Error; end

    # PayPal returned an unexpected error message
    class UnknownResponse < ::Paypal::Permissions::Error
      attr_accessor :response_code

      def initialize(response_code, message)
        @response_code = response_code
        @message = message
      end
    end

    # PayPal returned a well formatted error message
    class FaultMessage < Error
      attr_accessor :timestamp, :ack, :correlation_id, :build, :errors

      class ErrorInformation
        attr_accessor :category, :domain, :subdomain, :error_id, :message, :parameter, :severity

        def initialize(options = {}, error_number = 0)
          @category  = options["error(#{error_number}).category"]
          @domain    = options["error(#{error_number}).domain"]
          @subdomain = options["error(#{error_number}).subdomain"]
          @error_id  = options["error(#{error_number}).errorId"]
          @message   = options["error(#{error_number}).message"]
          @parameter = options["error(#{error_number}).parameter"]
          @severity  = options["error(#{error_number}).severity"]
        end
      end

      def initialize(options = {})
        @timestamp      = options['timestamp']
        @ack            = options['ack'].to_s.downcase.to_sym
        @correlation_id = options['correlationId']
        @build          = options['build']
        @errors         = collect_errors(options)

        @message = @ack
      end

      private
      def collect_errors(options={})
        errors = []
        error_number = 0

        while options["error(#{error_number}).errorId"]
          errors << ::Paypal::Permissions::FaultMessage::ErrorInformation.new(options, error_number)
          error_number = error_number + 1
        end
        errors
      end
    end
  end
end
