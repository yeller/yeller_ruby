require 'action_controller/test_case'
namespace :yeller do
  desc "verify your yeller gem installation by sending a test exception to yeller's servers"
  task :verify => [:environment] do
    Dir["app/controllers/application*.rb"].each { |file| require(File.expand_path(file)) }

    catcher = Yeller::Rails::ActionControllerCatchingHooks

    if !([ActionController::Base, ActionDispatch::DebugExceptions, ActionDispatch::ShowExceptions, ApplicationController].any? {|x| x.included_modules.include?(catcher) })
      puts "YELLER: NO RAILS INITIALIZATION DETECTED"
      puts "this is likely our problem, email tcrayford@yellerapp.com"
      exit 126
    end

    client = Yeller::Rack.instance_variable_get('@client')
    if client.token.nil? || client.token == 'YOUR_API_TOKEN_HERE'
      puts "NO YELLER API TOKEN DETECTED: your api token was set to #{client.token.inspect}"
      puts "Yeller needs an api key configured. Check the README: https://github.com/tcrayford/yeller_ruby to find out how to do that"
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


    Rails.application.routes.draw do
      root 'yeller_verification#verify'
    end

    env = Rack::MockRequest.env_for('http://example.com')
    Rails.application.call(env)

    client = Yeller::Rack.instance_variable_get('@client')
    if client.reported_error?
      Kernel.puts "SUCCESS: yeller-verified token=\"#{client.token}\""
    else
      if !client.enabled?
        Kernel.puts "ERROR: CLIENT NOT ENABLED yeller-verification-failed enabled=#{client.enabled?} token=\"#{client.token}\""
        Kernel.puts "Yeller rails client not enabled, check development_environments setting"
      else
        Kernel.puts "ERROR yeller-verification-failed enabled=#{client.enabled?} token=\"#{client.token}\""
      end
      exit 126
    end
  end
end
