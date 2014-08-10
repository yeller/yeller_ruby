module Yeller
  class IgnoringClient
    def report(*_)
    end

    def enabled?
      false
    end
  end
end
