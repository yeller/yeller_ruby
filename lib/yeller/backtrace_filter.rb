module Yeller
  class BacktraceFilter
    attr_reader :filename_filters, :method_filters, :project_root
    def initialize(filename_filters, method_filters, project_root)
      @filename_filters = filename_filters
      @method_filters = method_filters
      @project_root = project_root
    end

    def filter(trace)
      trace.map do |frame|
        in_app = filter_in_app(frame)
        res = [filter_filename(in_app[0]), in_app[1], filter_method(in_app[2])]
        if in_app[3]
          res << in_app[3]
        end
        res
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

    def filter_in_app(frame)
      filename = frame[0]
      if filename.start_with?(project_root)
        frame << {"in-app" => true}
      end
      frame
    end
  end
end
