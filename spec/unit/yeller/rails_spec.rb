require File.expand_path('../../../../lib/yeller/rails', __FILE__)

describe Yeller::Rails::ControllerMethods do
  class FakeUnitController
    include Yeller::Rails::ControllerMethods
    def params
      {:the_params => true}
    end

    def request
      Rack::Request.new({})
    end
  end

  class FakeUser
    attr_reader :id
    def initialize(id)
      @id = id
    end
  end

  subject { FakeUnitController.new }

  describe "#_yeller_custom_data" do
    it "returns params if it's there" do
      the_params = {:the_params => true}
      subject._yeller_custom_data[:params].should == the_params
    end

    it "returns yeller user data if it's there" do
      controller = subject
      def controller.yeller_user_data
        {"user" => {"id" => 123}}
      end
      controller._yeller_custom_data["user"]["id"].should == 123
    end

    it "returns yeller user data based on the current user" do
      controller = subject
      def controller.current_user
        FakeUser.new(123)
      end
      controller._yeller_custom_data["user"]["id"].should == 123
    end

    it "returns custom_data if overridden" do
      controller = subject
      def controller.yeller_custom_data
        {"current_organization" => {"name" => "github"}}
      end
      controller._yeller_custom_data["current_organization"]["name"].should == "github"
    end
  end
end
