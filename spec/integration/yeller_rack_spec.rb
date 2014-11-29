require File.expand_path('../../../lib/yeller', __FILE__)
require File.expand_path('../../../lib/yeller/rack', __FILE__)
require File.expand_path('../support/fake_yeller_api', __FILE__)

describe Yeller::Rack do
  class CustomException < StandardError; end

  it "submits an error" do
    FakeYellerApi.start('token', 8888) do |yeller_api|
      Yeller::Rack.configure do |client|
        client.token = 'token'
        client.remove_default_servers
        client.environment = 'production'
        client.add_insecure_server "localhost", 8888
      end
      app = Yeller::Rack.new(lambda {|req| raise CustomException })
      env = Rack::MockRequest.env_for("http://example.com")
      expect do
        app.call(env)
      end.to raise_error(CustomException)
      yeller_api.should have_received_exception(CustomException.new)
    end
  end
end
