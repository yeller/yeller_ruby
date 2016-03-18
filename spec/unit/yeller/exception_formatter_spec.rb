require File.expand_path('../../../../lib/yeller/exception_formatter', __FILE__)


describe Yeller::ExceptionFormatter do
  module Foo
    class CustomException < StandardError; end
  end

  def identity_backtrace_filter
    Yeller::ExceptionFormatter::IdentityBacktraceFilter.new
  end

  it "it returns the right message" do
    error = RuntimeError.new('an_message')
    hash = Yeller::ExceptionFormatter.format(error)
    hash[:message].should == 'an_message'
  end

  it "returns the right type" do
    error = RuntimeError.new
    hash = Yeller::ExceptionFormatter.format(error)
    hash.fetch(:type).should == 'RuntimeError'
  end

  it "returns scoped exception types" do
    error = Foo::CustomException.new
    hash = Yeller::ExceptionFormatter.format(error)
    hash.fetch(:type).should == 'Foo::CustomException'
  end

  it "sets message to an empty string if none was given" do
    error = RuntimeError.new
    hash = Yeller::ExceptionFormatter.format(error)
    hash.fetch(:message).should be_nil
  end

  it "unwraps nested exceptions" do
    error = nil
    begin
      begin
        raise Foo::CustomException.new("custom")
      rescue => e
        raise RuntimeError.new(e)
      end
    rescue => e
      error = e
    end
    hash = Yeller::ExceptionFormatter.format(error)
    if error.respond_to?(:cause)
      hash.fetch(:type).should == 'Foo::CustomException'
    else
      hash.fetch(:type).should == 'RuntimeError'
    end
  end

  if RuntimeError.new.respond_to?(:cause)
    it "unwraps nested exceptions into causes" do
      error = nil
      begin
        begin
          raise Foo::CustomException.new("custom")
        rescue => e
          raise RuntimeError.new(e)
        end
      rescue => e
        error = e
      end
      hash = Yeller::ExceptionFormatter.format(error)
      hash.fetch(:causes).fetch(0).fetch(:type).should == 'RuntimeError'
    end

    it "handles recursive causes" do
      error = nil
      begin
        e = RuntimeError.new
        e.stub(:cause).and_return(e)
        raise e
      rescue => e
        error = e
      end
      hash = Yeller::ExceptionFormatter.format(error)
      hash.fetch(:type).should == 'RuntimeError'
    end
  end

  describe "backtraces" do
    it "formats backtraces" do
      backtrace = [
        "app/models/user.rb:13:in `magic'",
        "app/controllers/users_controller.rb:8:in `index'"
      ]
      error = double(:error, :backtrace => backtrace, :message => 'an_message')
      hash = Yeller::ExceptionFormatter.format(error)
      hash[:stacktrace].should == [
        ["app/models/user.rb", "13", "magic"],
        ["app/controllers/users_controller.rb", "8", "index"]
      ]
    end

    it "copes with no backtrace (for unraised exceptions)" do
      error = RuntimeError.new
      hash = Yeller::ExceptionFormatter.format(error)
      hash[:stacktrace].should be_empty
    end
  end

  it "passes along custom data passed through the options" do
    error = RuntimeError.new
    hash = Yeller::ExceptionFormatter.format(
      error,
      identity_backtrace_filter,
      :custom_data => {:params => {:user_id => 1}})
    hash[:"custom-data"].should == {:params => {:user_id => 1}}
  end

  describe "url" do
    it "passes along the url passed in the options hash" do
      error = RuntimeError.new
      hash = Yeller::ExceptionFormatter.format(
        error,
        identity_backtrace_filter,
        :url => "http://example.com/foobar")
      hash[:url].should == "http://example.com/foobar"
    end

    it "doesn't pass along a url if it isn't present" do
      error = RuntimeError.new
      hash = Yeller::ExceptionFormatter.format(error)
      hash.should_not have_key(:url)
    end
  end

  describe "location" do
    it "passes along the location passed in the options hash" do
      error = RuntimeError.new
      hash = Yeller::ExceptionFormatter.format(
        error,
        identity_backtrace_filter,
        :location => "ExampleController#show")
      hash[:location].should == "ExampleController#show"
    end

    it "doesn't pass along a url if it isn't present" do
      error = RuntimeError.new
      hash = Yeller::ExceptionFormatter.format(error)
      hash.should_not have_key(:location)
    end
  end
end
