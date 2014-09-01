require_relative '../../../lib/yeller'
require_relative '../../../lib/yeller/rails'

describe Yeller::Rails::ControllerMethods do
  class FakeController
    include Yeller::Rails::ControllerMethods
    def params
      {:the_params => true}
    end

    def env
      {}
    end
  end

  describe "#_yeller_custom_data" do
    it "returns params if it's there" do
      the_params = {:the_params => true}
      FakeController.new._yeller_custom_data[:params].should == the_params
    end

    it "returns yeller user data if it's there" do
      controller = FakeController.new
      def controller.yeller_user_data
        {"user" => {"id" => 123}}
      end
      controller._yeller_custom_data["user"]["id"].should == 123
    end

    it "returns yeller user data based on the current user" do
      controller = FakeController.new
      def controller.current_user
        OpenStruct.new(:id => 123)
      end
      controller._yeller_custom_data["user"]["id"].should == 123
    end

    it "returns custom_data if overridden" do
      controller = FakeController.new
      def controller.yeller_custom_data
        {"current_organization" => {"name" => "github"}}
      end
      controller._yeller_custom_data["current_organization"]["name"].should == "github"
    end
  end
end
