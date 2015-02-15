require 'net/http'
require 'yajl/json_gem'

require File.expand_path('../yeller/backtrace_filter', __FILE__)
require File.expand_path('../yeller/client', __FILE__)
require File.expand_path('../yeller/ignoring_client', __FILE__)
require File.expand_path('../yeller/configuration', __FILE__)
require File.expand_path('../yeller/exception_formatter', __FILE__)
require File.expand_path('../yeller/server', __FILE__)
require File.expand_path('../yeller/skip_exceptions', __FILE__)
require File.expand_path('../yeller/version', __FILE__)
require File.expand_path('../yeller/startup_params', __FILE__)
require File.expand_path('../yeller/log_error_handler', __FILE__)
require File.expand_path('../yeller/verify_log', __FILE__)
require File.expand_path('../yeller/rails/tasks', __FILE__)

module Yeller
  def self.client(*blocks, &block)
    config = Yeller::Configuration.new
    if block_given?
      block.call(config)
    end
    blocks.each do |b|
      b.call(config)
    end
    build_client(config)
  end

  def self.build_client(config)
    if config.ignore_exceptions?
      Yeller::IgnoringClient.new(config.token)
    else
      Yeller::Client.new(
        config.servers,
        config.token,
        Yeller::StartupParams.defaults(config.startup_params),
        Yeller::BacktraceFilter.new(config.backtrace_filename_filters, config.backtrace_method_filters, config.project_root),
        config.error_handler,
        config.skip_exceptions
      )
    end
  end
end
