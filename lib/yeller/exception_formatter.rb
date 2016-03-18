require 'set'
module Yeller
  class ExceptionFormatter
    BACKTRACE_FORMAT = %r{^((?:[a-zA-Z]:)?[^:]+):(\d+)(?::in `([^']+)')?$}.freeze

    class IdentityBacktraceFilter
      def filter(trace)
        trace
      end
    end

    def self.format(exception, backtrace_filter=IdentityBacktraceFilter.new, options={})
      all_causes = process_causes(exception)
      root = all_causes.fetch(0, exception)
      causes = all_causes.drop(1)
      new(root, causes || [], backtrace_filter, options).to_hash
    end

    def self.process_causes(exception)
      unwrap_causes(exception)
    end

    def self.unwrap_causes(exception)
      causes = [exception]
      previously_seen = Set.new([exception.object_id])
      while exception.respond_to?(:cause) && exception.cause
        cause = exception.cause
        if previously_seen.include?(cause.object_id)
          break
        end
        causes << cause
        previously_seen << cause.object_id
        exception = cause
      end
      causes.reverse!
    end

    attr_reader :type, :options, :backtrace_filter

    def initialize(e, causes, backtrace_filter, options)
      exception = e
      @type = exception.class.name
      @message = exception.message
      @backtrace = exception.backtrace
      @causes = causes
      @backtrace_filter = backtrace_filter
      @options = options
    end

    def message
      # If a message is not given, rubby will set message to the class name
      @message == type ? nil : @message
    end

    def formatted_backtrace(backtrace)
      return [] unless backtrace

      original_trace = backtrace.map do |line|
        _, file, number, method = line.match(BACKTRACE_FORMAT).to_a
        [file, number, method]
      end
      backtrace_filter.filter(original_trace)
    end

    def causes
      @causes.map do |cause|
        {
          :type => cause.class.name,
          :message => cause.message,
          :stacktrace => formatted_backtrace(cause.backtrace),
        }
      end
    end

    def to_hash
      result = {
        :message => message,
        :stacktrace => formatted_backtrace(@backtrace),
        :type => type,
        :"custom-data" => options.fetch(:custom_data, {}),
        :causes => causes,
      }
      result[:url] = options[:url] if options.key?(:url)
      result[:location] = options[:location] if options.key?(:location)
      result
    end
  end
end
