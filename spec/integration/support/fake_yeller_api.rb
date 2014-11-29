require 'sinatra'
require 'thin'
require 'webmock'

class FakeYellerApi
  extend WebMock::API
  HOST = "localhost"
  attr_reader :token, :received

  def self.start(token, *ports, &block)
    apis  = ports.map { new(token) }

    ports.zip(apis).each do |port, api|
      app = FakeYellerApi::App.new!(api)
      stub_request(:any, /localhost:#{port}/).to_rack(app)
    end
    block.call(*apis)
  end

  def initialize(token)
    @token = token
    @received = []
  end

  def receive!(params)
    @received << params
  end

  def receive_deploy!(params)
    @deploy_params = params
  end

  def has_received_exception_once?(e)
    req = @received.first
    req &&
      e.class.name == req.fetch('type') &&
      @received.count == 1
  end

  def has_received_deploy?(revision)
    @deploy_params && @deploy_params[:revision] == revision
  end

  class App < Sinatra::Base
    def initialize(api)
      @api = api
      super
    end

    post '/:api_token/?' do
      if params[:api_token] == @api.token
        exception = JSON.load(request.body.read)
        @api.receive!(exception)
      end
      'success'
    end

    post '/:api_token/deploys/?' do
      if params[:api_token] == @api.token
        @api.receive_deploy!(params)
      end
      'success'
    end
  end
end

RSpec::Matchers.define :have_received_exception_once do |expected|
  match do |actual|
    actual.has_received_exception_once?(expected)
  end

  failure_message_for_should do |actual|
    req = actual.received.first
    if actual.received.empty?
      "expected to have received an exception, but received 0 exceptions"
    elsif expected.class.name != req.fetch('type')
      "expected to have received an exception of type #{expected.class.name}, but got #{req} #{req.fetch('stacktrace').map(&:inspect).join("\n")}"
    elsif actual.received.count != 1
      "expected to receive one error, but received more than one error: #{actual.received.map {|x| x.fetch('type')}}"
    end
  end
end
