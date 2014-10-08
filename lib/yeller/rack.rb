require 'rack/request'
require File.expand_path('../../yeller', __FILE__)

module Yeller
  class Rack
    def self.configure(&block)
      @config_blocks ||= []
      @config_blocks << block
      @client = Yeller.client(*@config_blocks)
    end

    def self.report(exception, options={})
      Yeller::VerifyLog.reporting_to_yeller_rack!
      @client.report(exception, options)
    end

    def self.enabled?
      return false unless @client
      @client.enabled?
    end

    def self.client
      @client
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        @app.call(env)
      rescue Exception => exception
        Yeller::Rack.rescue_rack_exception(exception, env)
        raise exception
      end
    end

    def self.rescue_rack_exception(exception, env)
      request = ::Rack::Request.new(env)
      Yeller::Rack.report(
        exception,
        :url => request.url,
        :custom_data => {
          :params => request.params,
          :session => env.fetch('rack.session', {}),
      })
    end
  end
end
