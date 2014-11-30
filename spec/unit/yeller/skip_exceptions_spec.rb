require File.expand_path('../../../../lib/yeller/skip_exceptions', __FILE__)

describe Yeller::SkipExceptions do
  class CustomException1 < StandardError; end

  it "skips an exception in the given array" do
    skipper = Yeller::SkipExceptions.new(['CustomException1'], Proc.new {})
    skipper.skip?(CustomException1.new).should be_true
  end

  it "doesn't skip exceptions not in the array" do
    skipper = Yeller::SkipExceptions.new(['CustomException1'], Proc.new {})
    skipper.skip?(StandardError.new).should be_false
  end

  it "skips an exception if the callback returns true" do
    skipper = Yeller::SkipExceptions.new([], Proc.new { true })
    skipper.skip?(CustomException1.new).should be_true
  end

  it "doesn't skip exceptions if the callback is false" do
    skipper = Yeller::SkipExceptions.new([], Proc.new { false })
    skipper.skip?(StandardError.new).should be_false
  end
end
