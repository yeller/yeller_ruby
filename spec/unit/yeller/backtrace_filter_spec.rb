require File.expand_path('../../../../lib/yeller/backtrace_filter', __FILE__)

describe Yeller::BacktraceFilter do
  it "filters out the defined filters (sample is project root)" do
    project_root = "/var/www/my_rails_app"
    filter = Yeller::BacktraceFilter.new(
      [[project_root, '[PROJECT_ROOT]']],
      [],
      '/app')
    filtered = filter.filter(
      [
        ["/var/www/my_rails_app/app/controllers/foo_controller.rb",
          "10",
          "index"]
    ]
    )
    filtered.should == [
      ["[PROJECT_ROOT]/app/controllers/foo_controller.rb", "10", "index"]
    ]
  end

  it "only filters out the first occurrence of the filter" do
    project_root = "/app"
    filter = Yeller::BacktraceFilter.new(
      [[project_root, 'PROJECT_ROOT']],
      [],
      '/my_rails_app')
    filtered = filter.filter(
      [
        ["/app/app/controllers/foo_controller.rb",
          "10",
          "index"]
    ]
    )
    filtered.should == [
      ["PROJECT_ROOT/app/controllers/foo_controller.rb", "10", "index"]
    ]
  end

  it "filters method names" do
    filter = Yeller::BacktraceFilter.new(
      [],
      [["foo", "bar"]],
      '/app')
    filtered = filter.filter(
      [
        ["foo.rb",
          "10",
          "foo"]
    ]
    )
    filtered.should == [
      ["foo.rb", "10", "bar"]
    ]
  end

  it "marks lines starting with the project root as in-app" do
    filter = Yeller::BacktraceFilter.new(
      [],
      [],
      '/app')
    filtered = filter.filter(
      [
        ["/app/foo.rb",
          "10",
          "foo"]
    ]
    )
    filtered.should == [
      ["/app/foo.rb", "10", "foo", {"in-app" => true}]
    ]
  end
end
