require 'action_controller/test_case'
namespace :yeller do
  desc "verify your yeller gem installation by sending a test exception to yeller's servers"
  task :verify => [:environment] do
    Dir["app/controllers/application*.rb"].each { |file| require(File.expand_path(file)) }

    catcher = Yeller::Rails::ActionControllerCatchingHooks

    if !([ActionController::Base, ActionDispatch::DebugExceptions, ActionDispatch::ShowExceptions, ApplicationController].any? {|x| x.included_modules.include?(catcher) })
      puts "NO INITIALIZATION"
      exit 126
    end

    class YellerVerifyException < RuntimeError; end

    Yeller::Rails.configure do |config|
      config.development_environments = []
    end

    class ApplicationController
      prepend_before_filter :verify_yeller

      def verify_yeller
        raise YellerVerifyException.new("verifying that yeller works")
      end

      def verify
      end

      def consider_all_requests_local
        false
      end

      def local_request?
        false
      end
    end

    class YellerVerificationController < ApplicationController; end

    puts "TOKEN: #{Yeller::Rack.instance_variable_get('@client').inspect}"

    Rails.application.routes.draw do
      root 'yeller_verification#verify'
    end

    env = Rack::MockRequest.env_for('http://example.com')
    Rails.application.call(env)
  end
end
