require 'set'
module Yeller
  class SkipExceptions
    def initialize(error_names)
      @error_names = Set.new(error_names)
    end

    def skip?(exception)
      @error_names.include?(exception.class.name)
    end
  end
end
