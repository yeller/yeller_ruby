require 'set'
module Yeller
  class SkipExceptions
    def initialize(error_names, callback)
      @error_names = Set.new(error_names)
      @callback = callback
    end

    def skip?(exception)
      @error_names.include?(exception.class.name) ||
        @callback.call(exception)
    end
  end
end
