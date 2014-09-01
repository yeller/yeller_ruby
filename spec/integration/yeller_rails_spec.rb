require_relative '../../lib/yeller'
require_relative '../../lib/yeller/rails'
require_relative 'support/fake_yeller_api'
require 'action_controller'
require 'action_controller/metal'

describe Yeller::Rails do
  class CustomException < StandardError; end
  class FakeController < ActionController::Base
    def index
      puts "LOOOL"
      raise CustomException.new
    end
  end

  class Yeller::FakeRailsApp < Rails::Application
    config.secret_key_base = 'lol'
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
        root 'fake#index'
      end
      env = Rack::MockRequest.env_for("http://example.com")
      Rails.application.call(env)
      yeller_api.should have_received_exception(CustomException.new)
    end
  end
end
