module Yeller
  class BacktraceFilter
    attr_reader :filename_filters, :method_filters
    def initialize(filename_filters, method_filters)
      @filename_filters = filename_filters
      @method_filters = method_filters
    end

    def filter(trace)
      trace.map do |frame|
        [filter_filename(frame[0]), frame[1], filter_method(frame[2])]
      end
    end

    def filter_filename(filename)
      filename_filters.each do |filter|
        filename.sub!(filter[0], filter[1])
      end
      filename
    end

    def filter_method(method)
      return '' if method.nil?
      method_filters.each do |filter|
        method.gsub!(filter[0], filter[1])
      end
      method
    end
  end
end
