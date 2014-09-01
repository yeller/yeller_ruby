require 'rails'
require 'yeller'
require 'yeller/rack'

module Yeller
  class Rails
    def self.configure(&block)
      Yeller::Rack.configure do |config|
        config.error_handler = Yeller::LogErrorHandler.new(::Rails.logger)
        config.environment = ::Rails.env.to_s
        block.call(config)
      end
    end

    def self.enabled?
      Yeller::Rack.enabled?
    end

    def self.client
      Yeller::Rack.client
    end

    module ControllerMethods
      def _yeller_custom_data
        out = {
          :params => params,
          :session => env.fetch('rack.session', {})
        }
        out.merge!(yeller_user_data || {})
        if respond_to?(:yeller_custom_data)
          out.merge!(yeller_custom_data || {})
        end
        out
      end

      def yeller_user_data
        return {} unless respond_to?(:current_user)
        return {} unless current_user.respond_to?(:id)
        id = current_user.id
        return {} unless id.is_a?(Integer)
        {"user" => {"id" => id}}
      end
    end

    module ActionControllerCatchingHooks
      def self.included(base)
        base.send(:alias_method, :render_exception_without_yeller, :render_exception)
        base.send(:alias_method, :render_exception, :render_exception_with_yeller)
      end

      protected
      def render_exception_with_yeller(env, exception)
        controller = env['action_controller.instance']
        params = controller.send(:params)
        request = ::Rack::Request.new(env)
        Yeller::Rack.report(
          exception,
          :url => request.url,
          :location => "#{controller.class.to_s}##{params[:action]}",
          :custom_data => controller._yeller_custom_data
        )

        render_exception_without_yeller(env, exception)
      end
    end

    class Railtie < ::Rails::Railtie
      initializer "yeller.use_rack_middleware" do |app|
        app.config.middleware.insert 0, "Yeller::Rack"

        ActiveSupport.on_load :action_controller do
          include Yeller::Rails::ControllerMethods
        end
      end

      config.after_initialize do
        if defined?(::ActionDispatch::DebugExceptions)
          ::ActionDispatch::DebugExceptions.send(:include, Yeller::Rails::ActionControllerCatchingHooks)
        elsif defined(::ActionDispatch::ShowExceptions)
          ::ActionDispatch::ShowExceptions.send(:include, Yeller::Rails::ActionControllerCatchingHooks)
        end
      end
    end
  end
end
