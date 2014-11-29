require 'rails' rescue nil
rails_version = defined?(Rails.version) && Rails.version || defined?(Rails::VERSION::STRING) && Rails::VERSION::STRING
puts "RAILS_VERSION: #{rails_version.inspect}"
if rails_version && rails_version.to_f < 3
  require File.expand_path('../../../lib/yeller/verify_log', __FILE__)
  Yeller::VerifyLog.enable!
  require 'activesupport'
  require 'action_controller'
  require 'action_controller/test_case'
  require File.expand_path('../../../lib/yeller', __FILE__)
  require File.expand_path('../../../lib/yeller/rails', __FILE__)
  require File.expand_path('../support/fake_yeller_api', __FILE__)

  describe Yeller::Rails do
    class CustomException < StandardError; end
    class FakeController < ActionController::Base
      def index
        Yeller::VerifyLog.about_to_raise_exception_in_controller!
        raise CustomException.new
      end
    end

    it "submits an error" do
      FakeYellerApi.start('token', 8888) do |yeller_api|
        Yeller::Rails.configure do |client|
          client.token = 'token'
          client.remove_default_servers
          client.environment = 'production'
          client.add_insecure_server "localhost", 8888
        end

        request = ActionController::TestRequest.new("REQUEST_URI" => "/yeller_fake_controller")
        response = ActionController::TestResponse.new
        FakeController.new.process(request, response)
        unless yeller_api.has_received_exception_once?(CustomException.new)
          Yeller::StdoutVerifyLog.print_log!
        end
        yeller_api.should have_received_exception_once(CustomException.new)
      end
    end
  end
else
  require_relative '../../lib/yeller/verify_log'
  Yeller::VerifyLog.enable!
  require 'rails'
  require 'action_controller'
  require 'action_controller/metal'
  require 'action_controller/base'
  require_relative '../../lib/yeller'
  require_relative '../../lib/yeller/rails'
  require_relative 'support/fake_yeller_api'

  describe Yeller::Rails do
    class CustomException < StandardError; end
    class FakeController < ActionController::Base
      def index
        raise CustomException.new
      end
    end

    class Yeller::FakeRailsApp < Rails::Application
      config.secret_key_base = 'lollollollollollollollollollollol'
      config.eager_load = true
    end

    it "submits an error" do
      FakeYellerApi.start('token', 8888) do |yeller_api|
        Yeller::Rails.configure do |client|
          client.token = 'token'
          client.remove_default_servers
          client.environment = 'production'
          client.add_insecure_server "localhost", 8888
        end
        Yeller::FakeRailsApp.initialize!
        Rails.application.routes.draw do
          get '/fake_yeller_verify' => 'fake#index'
        end
        env = Rack::MockRequest.env_for("http://example.com/fake_yeller_verify")
        Rails.application.call(env)
        unless yeller_api.has_received_exception_once?(CustomException.new)
          Yeller::StdoutVerifyLog.print_log!
        end
        yeller_api.should have_received_exception_once(CustomException.new)
      end
    end
  end
end
