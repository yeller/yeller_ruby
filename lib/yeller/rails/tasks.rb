require "actionpack/lib/action_dispatch/testing/test_request"
require "actionpack/lib/action_dispatch/testing/test_response"
namespace :yeller do
  desc "verify your yeller gem installation by sending a test exception to yeller's servers"
  task :verify => [:environment] do
    Dir["app/controllers/application*.rb"].each { |file| require(File.expand_path(file)) }

    class YellerVerifyException < RuntimeError; end

    Yeller::Rails.configure do |config|
      config.development_environments = []

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

      request = ActionController::TestRequest.new("REQUEST_URI" => "/yeller_verification_controller")
      response = ActionController::TestResponse.new
      YellerVerificationController.new.process(request, response)
    end
  end
end
