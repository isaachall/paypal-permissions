require 'spec_helper'

module Paypal::Permissions
  describe Paypal do
    it "should request permissions with multiple scopes" do
      VCR.use_cassette("request_permissions_multiple") do
        permission_data = @paypal.request_permissions(
          [:express_checkout, :direct_payment, :auth_capture, :refund, :transaction_details],
          'http://localhost/')

        permission_data[:token].should == 'AAAAAAATmjdbA3ADelJ6'
        permission_data[:permissions_url].should == 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_grant-permission&request_token=' + permission_data[:token]
      end
    end

    it "should request permissions with a single scopes" do
      VCR.use_cassette("request_permissions_single") do
        permission_data = @paypal.request_permissions(
          [:express_checkout],
          'http://localhost/')

        permission_data[:token].should == 'AAAAAAATmnP2wcRCp7Mc'
        permission_data[:permissions_url].should == 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_grant-permission&request_token=' + permission_data[:token]
      end
    end

    it "should get an access token" do
      VCR.use_cassette("get_access_token_valid") do
        access_data = @paypal.get_access_token('AAAAAAATmjdbA3ADelJ6','KVTI4zbTe.QW07vOqPpqYg')
        access_data[:token].should == 'M-RTGNyaZP5OMNIUxkH29I53eFvQhTJk3UfByH4pWfjSQHlj5csUVA'
        access_data[:token_secret].should == 'l1.rjYM659iL92IwDmnPFeDWUnU'
        access_data[:scopes].should == [:express_checkout, :refund, :direct_payment, :auth_capture, :transaction_details]
      end
    end

    describe "#lookup_permissions" do
      it "should lookup permissions" do
        VCR.use_cassette("lookup_permissions_multiple") do
          lookup_data = @paypal.lookup_permissions('M-RTGNyaZP5OMNIUxkH29I53eFvQhTJk3UfByH4pWfjSQHlj5csUVA')
          lookup_data[:scopes].should == [:express_checkout, :refund, :direct_payment, :auth_capture, :transaction_details]
        end
      end
    end

    describe "#cancel_permission" do
      it "should cancel permmission successfully" do
        VCR.use_cassette("cancel_permission") do
          cancel_data = @paypal.cancel_permissions('M-RTGNyaZP5OMNIUxkH29I53eFvQhTJk3UfByH4pWfjSQHlj5csUVA')
          cancel_data.should be_true
        end
      end

      it "should raise a FaultMessage when canceling an invalid permmission" do
        lambda {
          VCR.use_cassette("cancel_permission_invalid") do
            @paypal.cancel_permissions('M-RTGNyaZP5OMNIUxkH29I53eFvQhTJk3UfByH4pWfjSQHlj5csUVA')
          end
        }.should raise_error(::Paypal::Permissions::FaultMessage)
      end
    end
  end
end

