require 'sinatra'
require 'thin'
require 'webmock'

class FakeYellerApi
  extend WebMock::API
  HOST = "localhost"
  attr_reader :token

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
  end

  def receive!(params)
    @received_params = params
  end

  def receive_deploy!(params)
    @deploy_params = params
  end

  def has_received_exception?(e)
    @received_params && e.class.name == @received_params.fetch('type')
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
