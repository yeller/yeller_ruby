module Yeller
  class NoopLog
    def self.monkey_patching_rails!(rails_class)
    end

    def self.render_exception_with_yeller!
    end

    def self.error_reporting_rails_error!(e)
    end

    def self.action_controller_instance_not_in_env!
    end

    def self.reported_to_api!
    end

    def self.error_code_from_api!(response)
    end

    def self.exception_from_api!(e)
    end

    def self.about_to_raise_exception_in_controller!
    end

    def self.reporting_to_yeller_rack!
    end
  end

  class VerifyLog
    @logger = NoopLog

    def self.enable!
      @logger = StdoutVerifyLog
    end

    def self.monkey_patching_rails!(rails_class)
      @logger.monkey_patching_rails!(rails_class)
    end

    def self.render_exception_with_yeller!
      @logger.render_exception_with_yeller!
    end

    def self.error_reporting_rails_error!(e)
      @logger.error_reporting_rails_error!(e)
    end

    def self.action_controller_instance_not_in_env!
      @logger.action_controller_instance_not_in_env!
    end

    def self.reported_to_api!
      @logger.reported_to_api!
    end

    def self.error_code_from_api!(response)
      @logger.error_code_from_api!(response)
    end

    def self.exception_from_api!(e)
      @logger.exception_from_api!(e)
    end

    def self.about_to_raise_exception_in_controller!
      @logger.about_to_raise_exception_in_controller!
    end

    def self.reporting_to_yeller_rack!
      @logger.reporting_to_yeller_rack!
    end
  end

  class StdoutVerifyLog
    def self.print_log!
      @log ||= []
      @log.each do |line|
        puts line
      end
    end

    def self.monkey_patching_rails!(rails_class)
      info("monkeypatching rails #{rails_class}")
    end

    def self.render_exception_with_yeller!
      info("rendering exception with yeller")
    end

    def self.error_reporting_rails_error!(e)
      error("error reporting rails error, please contact rails@yellerapp.com with this message:\n" +
           e.inspect + "\n" + e.backtrace.join("\n"))
    end

    def self.action_controller_instance_not_in_env!
      warn("rack env didn't contain 'action_controller.instance', which should be set from rails.\n" +
           "Errors will still be logged, but they'll be missing a lot of useful information\n" +
           "check that your middleware doesn't mess with that key, and please contact rails@yellerapp.com for more assistance")
    end

    def self.reported_to_api!
      info("reported to api successfully!")
    end

    def self.error_code_from_api!(response)
      error("got a non successful response from yeller's api!: #{response.code} #{response.body}" +
           "\ncheck the api token is correct, and if you're still getting this error, contact rails@yellerapp.com")
    end

    def self.exception_from_api!(e)
      error("got an exception whilst sending the test error to yeller's api servers. Please contact rails@yellerapp.com with this message for help debugging.\n" +
           e.inspect + "\n" + e.backtrace.join("\n"))
    end

    def self.about_to_raise_exception_in_controller!
      info("about to raise exception in fake controller")
    end

    def self.reporting_to_yeller_rack!
      info("reporting via Yeller::Rack")
    end

    def self.info(message)
      @log ||= []
      @log << "yeller: #{message}"
    end

    def self.warn(message)
      info(red("WARNING:"))
      info(red(message))
    end

    def self.error(message)
      info(red("ERROR DETECTED:"))
      info(red(message))
    end

    def self.red(message)
      "\033[31m#{message}\033[0m"
    end
  end
end
