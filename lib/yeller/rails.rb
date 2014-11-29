require File.expand_path('../../yeller', __FILE__)
require File.expand_path('../../yeller/rack', __FILE__)

module Yeller
  class Rails
    def self.configure(&block)
      Yeller::Rack.configure do |config|
        if defined?(::Rails)
          config.error_handler = Yeller::LogErrorHandler.new(::Rails.logger)
          config.environment = ::Rails.env.to_s
        elsif ENV['RAILS_ENV']
          config.environment = ENV['RAILS_ENV']
        end
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
          :session => request.env.fetch('rack.session', {})
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

    module Rails3AndFourCatchingHooks
      def self.included(base)
        base.send(:alias_method, :render_exception_without_yeller, :render_exception)
        base.send(:alias_method, :render_exception, :render_exception_with_yeller)
      end

      def render_exception_with_yeller(env, exception)
        Yeller::VerifyLog.render_exception_with_yeller!
        begin
          request = ::Rack::Request.new(env)
          controller = env['action_controller.instance']

          if controller
            params = controller.send(:params)
            Yeller::Rack.report(
              exception,
              :url => request.url,
              :location => "#{controller.class.to_s}##{params[:action]}",
              :custom_data => controller._yeller_custom_data
            )
          else
            Yeller::VerifyLog.action_controller_instance_not_in_env!
            Yeller::Rack.report(
              exception,
              :url => request.url
            )
          end
        rescue => e
          Yeller::VerifyLog.error_reporting_rails_error!(e)
        end
      end
    end

    module Rails2CatchingHooks
      def self.included(base)
        Yeller::VerifyLog.monkey_patching_rails!("ActionController::Base.rescue_action_in_public")
        base.send(:alias_method, :rescue_action_in_public_without_yeller, :rescue_action_in_public)
        base.send(:alias_method, :rescue_action_in_public, :rescue_public_exception_with_yeller)

        Yeller::VerifyLog.monkey_patching_rails!("ActionController::Base.rescue_action_locally")
        base.send(:alias_method, :rescue_action_locally_without_yeller, :rescue_action_locally)
        base.send(:alias_method, :rescue_action_locally, :rescue_local_exception_with_yeller)
      end

      protected
      def rescue_public_exception_with_yeller(exception)
        _send_to_yeller(exception)
        rescue_action_in_public_without_yeller(exception)
      end

      def rescue_local_exception_with_yeller(exception)
        _send_to_yeller(exception)
        rescue_action_locally_without_yeller(exception)
      end

      def _send_to_yeller(exception)
        Yeller::VerifyLog.render_exception_with_yeller!
        controller = self
        params = controller.send(:params)
        Yeller::Rack.report(
          exception,
          :url => request.url,
          :location => "#{controller.class.to_s}##{params[:action]}",
          :custom_data => controller._yeller_custom_data
        )
      end
    end

    def self.monkeypatch_rails3!
      if defined?(::ActionDispatch::DebugExceptions)
        ::ActionDispatch::DebugExceptions.send(:include, Yeller::Rails::Rails3AndFourCatchingHooks)
      end
      if defined?(::ActionDispatch::ShowExceptions)
        ::ActionDispatch::ShowExceptions.send(:include, Yeller::Rails::Rails3AndFourCatchingHooks)
      end

      if defined?(::AcitonController)
        ::ActionController::Base.send(:include, Yeller::Rails::ControllerMethods)
      end
    end

    if defined?(::Rails) && defined?(::Rails::Railtie)
      class Railtie < ::Rails::Railtie
        initializer "yeller.use_rack_middleware" do |app|
          app.config.middleware.insert 0, "Yeller::Rack"
        end

        config.after_initialize do
          Yeller::Rails.monkeypatch_rails3!
       end
      end
    elsif defined?(ActionController::Base)
      ActionController::Base.send(:include, Yeller::Rails::Rails2CatchingHooks)
      ActionController::Base.send(:include, Yeller::Rails::ControllerMethods)
    end
  end
end
