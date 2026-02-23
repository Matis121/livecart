module Integrations
  class BaseClient
    attr_reader :integration, :connection

    def initialize(base_url:, integration:, timeout: 30)
      @integration = integration
      @connection = build_connection(base_url, timeout)
    end

    private

    def build_connection(base_url, timeout)
      Faraday.new(url: base_url) do |conn|
        # Request middleware
        conn.request :json
        conn.request :retry,
          max: 3,
          interval: 0.5,
          interval_randomness: 0.5,
          backoff_factor: 2,
          exceptions: [
            Faraday::TimeoutError,
            Faraday::ConnectionFailed,
            Errno::ETIMEDOUT
          ]

        # Response middleware
        conn.response :json, content_type: /\bjson$/
        conn.response :raise_error

        # Adapter
        conn.adapter Faraday.default_adapter

        # Timeouts
        conn.options.timeout = timeout
        conn.options.open_timeout = 10
      end
    end

    # HTTP Methods
    def get(path, params = {}, headers = {})
      with_error_handling do
        log_request(:get, path, params)
        response = connection.get(path, params, default_headers.merge(headers))
        log_response(response)
        response.body
      end
    end

    def post(path, body = {}, headers = {})
      with_error_handling do
        log_request(:post, path, body)
        response = connection.post(path, body, default_headers.merge(headers))
        log_response(response)
        response.body
      end
    end

    def put(path, body = {}, headers = {})
      with_error_handling do
        log_request(:put, path, body)
        response = connection.put(path, body, default_headers.merge(headers))
        log_response(response)
        response.body
      end
    end

    def delete(path, params = {}, headers = {})
      with_error_handling do
        log_request(:delete, path, params)
        response = connection.delete(path, params, default_headers.merge(headers))
        log_response(response)
        response.body
      end
    end

    # Override in subclasses to add authentication headers
    def default_headers
      {
        "User-Agent" => "LiveCart/1.0",
        "Accept" => "application/json"
      }
    end

    # Error handling wrapper
    def with_error_handling
      yield
    rescue Faraday::TimeoutError => e
      log_error("Timeout error: #{e.message}")
      raise IntegrationError, "Request timeout: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      log_error("Connection failed: #{e.message}")
      raise IntegrationError, "Connection failed: #{e.message}"
    rescue Faraday::ClientError => e
      log_error("Client error: #{e.response[:status]} - #{e.response[:body]}")
      raise IntegrationError, "API error: #{e.response[:status]}"
    rescue Faraday::ServerError => e
      log_error("Server error: #{e.response[:status]}")
      raise IntegrationError, "Server error: #{e.response[:status]}"
    rescue StandardError => e
      log_error("Unexpected error: #{e.class} - #{e.message}")
      raise IntegrationError, "Unexpected error: #{e.message}"
    end

    # Logging
    def log_request(method, path, payload)
      return unless Rails.env.development?

      Rails.logger.info("🔵 [#{integration.provider.upcase}] #{method.upcase} #{path}")
      Rails.logger.debug("   Payload: #{payload.inspect}") if payload.present?
    end

    def log_response(response)
      return unless Rails.env.development?

      Rails.logger.info("✅ [#{integration.provider.upcase}] Response: #{response.status}")
      Rails.logger.debug("   Body: #{response.body.inspect}")
    end

    def log_error(message)
      Rails.logger.error("❌ [#{integration.provider.upcase}] #{message}")
    end
  end

  # Custom error class for integration errors
  class IntegrationError < StandardError; end
end
