require File.expand_path('../version', __FILE__)

module Yeller
  class StartupParams
    PRODUCTION = 'production'.freeze
    VERSION = "yeller_rubby: #{Yeller::VERSION}"

    def self.defaults(options={})
      {
        :host => Socket.gethostname,
        :"application-environment" => application_environment(options),
        :"client-version" => VERSION,
      }
    end

    def self.application_environment(options)
      options[:"application-environment"] ||
        ENV['RAILS_ENV'] ||
        ENV['RACK_ENV'] ||
        ((defined?(::Rails) && Rails.respond_to?(:env)) ? Rails.env.to_s : nil) ||
        PRODUCTION
    end
  end
end
