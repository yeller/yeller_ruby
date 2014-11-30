module Yeller
  class Client
    attr_reader :backtrace_filter, :token

    def initialize(servers, token, startup_params, backtrace_filter, error_handler, skip_exceptions)
      @servers = servers
      @last_server = rand(servers.size)
      @startup_params = startup_params
      @token = token
      @backtrace_filter = backtrace_filter
      @error_handler = error_handler
      @skip_exceptions = skip_exceptions
      @reported_error = false
    end

    def report(exception, options={})
      unless @skip_exceptions.skip?(exception)
        hash = ExceptionFormatter.format(exception, backtrace_filter, options)
        serialized = JSON.dump(@startup_params.merge(hash))
        report_with_roundtrip(serialized, 0)
      end
    end

    def report_with_roundtrip(serialized, error_count)
      response = next_server.client.post("/#{@token}", serialized, {"Content-Type" => "application/json"})
      if response.code.to_i >= 200 && response.code.to_i <= 300
        Yeller::VerifyLog.reported_to_api!
        @reported_error ||= true
      else
        Yeller::VerifyLog.error_code_from_api!(response)
      end
    rescue StandardError => e
      if error_count <= (@servers.size * 2)
        report_with_roundtrip(serialized, error_count + 1)
      else
        Yeller::VerifyLog.exception_from_api!(e)
        @error_handler.handle(e)
      end
    end

    def record_deploy(revision, user, environment)
      post = Net::HTTP::Post.new("/#{@token}/deploys")
      post.set_form_data('revision' => revision,
                         'user' => user,
                         'environment' => environment)
      next_server.client.request(post)
    end

    def enabled?
      true
    end

    def reported_error?
      @reported_error
    end

    def inspect
      "#<Yeller::Client enabled=true token=#{@token.inspect}>"
    end

    private

    def next_server
      index = @last_server
      @last_server = (index + 1) % @servers.size
      @servers[index]
    end
  end
end
