module Integrations
  class Result
    attr_reader :data, :errors, :message, :updated_count, :failed_count

    def self.success(data: nil, message: nil, updated_count: 0, failed_count: 0)
      new(success: true, data: data, message: message, updated_count: updated_count, failed_count: failed_count)
    end

    def self.failure(errors: [], message: nil, data: nil)
      new(success: false, data: data, errors: Array(errors), message: message)
    end

    def success? = @success
    def failure? = !@success

    private

    def initialize(success:, data: nil, errors: [], message: nil, updated_count: 0, failed_count: 0)
      @success = success
      @data = data
      @errors = errors
      @message = message
      @updated_count = updated_count
      @failed_count = failed_count
    end
  end
end
