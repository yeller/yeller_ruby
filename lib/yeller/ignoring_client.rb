module Yeller
  class IgnoringClient
    attr_reader :token
    def initialize(token)
      @token = token
    end

    def report(*_)
    end

    def enabled?
      false
    end

    def reported_error?
      false
    end
  end
end
