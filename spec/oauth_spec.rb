require 'spec_helper'

module Paypal::Permissions
  describe Oauth do
    before(:each) do
      @api_key      = 'user.test.com'
      @secret       = '1234567890'
      @token        = '1234567890123456789012345678901234567890'
      @token_secret = '1234567890'
      @http_method  = 'POST'
      @endpoint     = 'https://api.paypal.com/nvp'
    end

    it "should calculate a X-PP-AUTHORIZATION signature" do
      Time.stub!(:now).and_return '1311832612'
      sig = @paypal.generate_signature(@token, @token_secret, @http_method, @endpoint)
      sig.should == 'timestamp=1311832612,token=1234567890123456789012345678901234567890,signature=d6da5d66e0f33ca7415b420cedf6b7286f05cba3'
    end
  end
end
